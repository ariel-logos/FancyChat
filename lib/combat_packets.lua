-- lib/combat_packets.lua
--
-- Packet-based combat filter.  Inspects each 0x0028 action packet
-- and zeroes out the per-result `message` field for any action the
-- user has chosen to hide.  The modified packet is delivered to the
-- game via Ashita's `e.data_modified` mechanism, which preserves
-- the animation/damage/HP-change paths (those are driven by other
-- fields in the same packet) while suppressing only the chat line.
--
-- 0x0029 (orphan action-message packets - buffs wearing off, exp,
-- spirit bond, etc.) has no animation, so we use plain
-- `e.blocked = true` for those.
--
-- The codec (string_to_act / act_to_string + assemble_bit_packed)
-- is adapted from the Azu-XI fork of atom0s' simplelog
-- (lib/actionhandlers.lua).  Filter logic, scope enum, and
-- should_show hierarchy are fancychat-specific.
--
-- Called once per incoming packet from lifecycle.lua's existing
-- packet_in callback - we do NOT register our own handler.
--
-- Public API:
--   M.SCOPE_YOU / SCOPE_PET / SCOPE_PARTY / SCOPE_ALLIANCE
--     / SCOPE_TARGET / SCOPE_OTHERS
--   M.should_show(scope, level)
--   M.dispatch(e)

require('common')
local state       = require('lib.state')
local allSettings = state.allSettings

local M = {}

----------------------------------------------------------------------
-- Scope enum.
----------------------------------------------------------------------
M.SCOPE_YOU      = 1
M.SCOPE_PET      = 2
M.SCOPE_PARTY    = 3
M.SCOPE_ALLIANCE = 4
M.SCOPE_TARGET   = 5
M.SCOPE_OTHERS   = 6

----------------------------------------------------------------------
-- 0x028 codec.  Bit-packed wire format - bit offsets are absolute
-- from the start of the packet (not relative to the 5-byte standard
-- header).  Layout reference: Azu-XI fork of simplelog,
-- lib/actionhandlers.lua.  Reading uses Ashita's
-- `ashita.bits.unpack_be`; writing uses the local
-- `assemble_bit_packed` helper for cross-byte-boundary writes.
----------------------------------------------------------------------
local function string_to_act(packet)
    local t = {}
    if string.byte(packet) ~= 0x28 then return t end
    local bytes = packet:totable()

    t.size         = ashita.bits.unpack_be(bytes, 32,   8)
    t.actor_id     = ashita.bits.unpack_be(bytes, 40,  32)
    t.target_count = ashita.bits.unpack_be(bytes, 72,  10)
    t.category     = ashita.bits.unpack_be(bytes, 82,   4)
    t.param        = ashita.bits.unpack_be(bytes, 86,  16)
    t.unknown      = ashita.bits.unpack_be(bytes, 102, 16)
    t.recast       = ashita.bits.unpack_be(bytes, 118, 32)
    t.targets      = {}

    local offset = 150
    for i = 1, t.target_count do
        local target = {
            server_id    = ashita.bits.unpack_be(bytes, offset,    32),
            action_count = ashita.bits.unpack_be(bytes, offset+32,  4),
            actions      = {},
        }
        offset = offset + 36
        for n = 1, target.action_count do
            local a = {
                reaction       = ashita.bits.unpack_be(bytes, offset,     5),
                animation      = ashita.bits.unpack_be(bytes, offset+5,  12),
                effect         = ashita.bits.unpack_be(bytes, offset+17,  4),
                stagger        = ashita.bits.unpack_be(bytes, offset+21,  3),
                knockback      = ashita.bits.unpack_be(bytes, offset+24,  3),
                param          = ashita.bits.unpack_be(bytes, offset+27, 17),
                message        = ashita.bits.unpack_be(bytes, offset+44, 10),
                unknown        = ashita.bits.unpack_be(bytes, offset+54, 31),
                has_add_effect = ashita.bits.unpack_be(bytes, offset+85,  1) == 1,
            }
            offset = offset + 86
            if a.has_add_effect then
                a.add_effect_animation = ashita.bits.unpack_be(bytes, offset,     6)
                a.add_effect_effect    = ashita.bits.unpack_be(bytes, offset+6,   4)
                a.add_effect_param     = ashita.bits.unpack_be(bytes, offset+10, 17)
                a.add_effect_message   = ashita.bits.unpack_be(bytes, offset+27, 10)
                offset = offset + 37
            end
            a.has_spike_effect = ashita.bits.unpack_be(bytes, offset, 1) == 1
            offset = offset + 1
            if a.has_spike_effect then
                a.spike_effect_animation = ashita.bits.unpack_be(bytes, offset,     6)
                a.spike_effect_effect    = ashita.bits.unpack_be(bytes, offset+6,   4)
                a.spike_effect_param     = ashita.bits.unpack_be(bytes, offset+10, 14)
                a.spike_effect_message   = ashita.bits.unpack_be(bytes, offset+24, 10)
                offset = offset + 34
            end
            target.actions[n] = a
        end
        t.targets[i] = target
    end
    return t
end

-- Bit-packs `val` into the byte-array accumulator `out_t` (each
-- entry is a 1-char string, so `#out_t` is the current byte length).
-- `initial_length` and `final_length` are absolute bit positions
-- from the packet start.  Caller invokes this repeatedly with
-- monotonically increasing offsets; the partial last byte is
-- carried across writes that span a byte boundary.  Returns true
-- on success, false if `val` is not numeric/boolean.
--
-- The accumulator pattern replaces the previous string-concat loop,
-- which was O(n^2) per packet under PacketFilterEnabled fights.
local function assemble_bit_packed(out_t, val, initial_length, final_length)
    if type(val) == 'boolean' then
        val = val and 1 or 0
    elseif type(val) ~= 'number' then
        return false
    end
    local bits        = initial_length % 8
    local byte_length = math.ceil(final_length / 8)
    local out_val     = 0
    if bits > 0 and #out_t > 0 then
        out_val       = string.byte(out_t[#out_t])
        out_t[#out_t] = nil
    end
    out_val = out_val + val * 2 ^ bits
    while out_val > 0 do
        out_t[#out_t + 1] = string.char(out_val % 256)
        out_val = math.floor(out_val / 256)
    end
    while #out_t < byte_length do
        out_t[#out_t + 1] = '\0'
    end
    return true
end

local function act_to_string(original, act)
    if type(act) ~= 'table' or not act.targets then return original end

    -- Seed the accumulator with the first 4 bytes of the original
    -- packet (the header up to the size field at offset 32 bits).
    local out_t = {original:sub(1,1), original:sub(2,2),
                   original:sub(3,3), original:sub(4,4)}

    local function pack(val, lo, hi)
        return assemble_bit_packed(out_t, val, lo, hi)
    end

    if not pack(act.size,         32,  40) then return original end
    if not pack(act.actor_id,     40,  72) then return original end
    if not pack(act.target_count, 72,  82) then return original end
    if not pack(act.category,     82,  86) then return original end
    if not pack(act.param,        86, 102) then return original end
    if not pack(act.unknown,     102, 118) then return original end
    if not pack(act.recast,      118, 150) then return original end

    local offset = 150
    for i = 1, act.target_count do
        local target = act.targets[i]
        if not pack(target.server_id,    offset,      offset + 32) then return original end
        if not pack(target.action_count, offset + 32, offset + 36) then return original end
        offset = offset + 36
        for n = 1, target.action_count do
            local a = target.actions[n]
            if not pack(a.reaction,       offset,      offset + 5)  then return original end
            if not pack(a.animation,      offset + 5,  offset + 17) then return original end
            if not pack(a.effect,         offset + 17, offset + 21) then return original end
            if not pack(a.stagger,        offset + 21, offset + 24) then return original end
            if not pack(a.knockback,      offset + 24, offset + 27) then return original end
            if not pack(a.param,          offset + 27, offset + 44) then return original end
            if not pack(a.message,        offset + 44, offset + 54) then return original end
            if not pack(a.unknown,        offset + 54, offset + 85) then return original end
            if not pack(a.has_add_effect, offset + 85, offset + 86) then return original end
            offset = offset + 86
            if a.has_add_effect then
                if not pack(a.add_effect_animation, offset,      offset + 6)  then return original end
                if not pack(a.add_effect_effect,    offset + 6,  offset + 10) then return original end
                if not pack(a.add_effect_param,     offset + 10, offset + 27) then return original end
                if not pack(a.add_effect_message,   offset + 27, offset + 37) then return original end
                offset = offset + 37
            end
            if not pack(a.has_spike_effect, offset, offset + 1) then return original end
            offset = offset + 1
            if a.has_spike_effect then
                if not pack(a.spike_effect_animation, offset,      offset + 6)  then return original end
                if not pack(a.spike_effect_effect,    offset + 6,  offset + 10) then return original end
                if not pack(a.spike_effect_param,     offset + 10, offset + 24) then return original end
                if not pack(a.spike_effect_message,   offset + 24, offset + 34) then return original end
                offset = offset + 34
            end
        end
    end
    -- Pad any trailing bytes from the original (alignment / unused
    -- tail) so the modified packet keeps the original total length.
    while #out_t < #original do
        local pos = #out_t + 1
        out_t[pos] = original:sub(pos, pos)
    end
    return table.concat(out_t)
end

----------------------------------------------------------------------
-- Snapshot refresh.  Called from render.lua's d3d_present once per
-- frame on the RENDER thread.  Reads all the native entity/party/
-- target state (the unsafe-from-packet-thread calls) and bakes it
-- into the plain Lua tables on state.combatSnap.  The packet_in
-- dispatch then reads only from those tables - zero native calls,
-- zero cross-thread races, zero AVs from this code path.
----------------------------------------------------------------------
function M.refresh_snapshot()
    local snap   = state.combatSnap
    local pe     = GetPlayerEntity()
    local mm     = AshitaCore:GetMemoryManager()
    local party  = mm:GetParty()
    local target = mm:GetTarget()

    -- Self ID: prefer the entity-table value, fall back to party slot 0.
    snap.self_id = (pe and pe.ServerId)
                or party:GetMemberServerId(0)
                or 0

    -- Pet ID: 0 unless we currently have a pet and its entity slot resolves.
    local pet_id = 0
    if pe and pe.PetTargetIndex and pe.PetTargetIndex ~= 0 then
        local pet = GetEntity(pe.PetTargetIndex)
        if pet and pet.ServerId then pet_id = pet.ServerId end
    end
    snap.pet_id = pet_id

    -- Rebuild party / alliance hash sets from scratch.  Reusing the
    -- existing tables (rather than allocating new ones) keeps GC
    -- pressure down on long sessions: clear-and-fill instead of
    -- replace-the-table.
    local party_set = snap.party_set
    for k in pairs(party_set) do party_set[k] = nil end
    for i = 1, 5 do
        if party:GetMemberIsActive(i) ~= 0 then
            local sid = party:GetMemberServerId(i)
            if sid and sid ~= 0 then party_set[sid] = true end
        end
    end

    local alliance_set = snap.alliance_set
    for k in pairs(alliance_set) do alliance_set[k] = nil end
    for i = 6, 17 do
        if party:GetMemberIsActive(i) ~= 0 then
            local sid = party:GetMemberServerId(i)
            if sid and sid ~= 0 then alliance_set[sid] = true end
        end
    end

    -- Engaged-target IDs: player's current battle target plus every
    -- party member's battle target (so an unclaimed friendly tank
    -- holding the mob still counts as TARGET scope).
    local target_set = snap.target_set
    for k in pairs(target_set) do target_set[k] = nil end
    if target then
        local tsid
        if target:GetIsSubTargetActive() == 0 then
            tsid = target:GetServerId(0)
        else
            tsid = target:GetServerId(1)
        end
        if tsid and tsid ~= 0 then target_set[tsid] = true end
    end
    for i = 0, 17 do
        if party:GetMemberIsActive(i) ~= 0 then
            local tgt_idx = party:GetMemberTargetIndex(i)
            if tgt_idx ~= 0 then
                local e = GetEntity(tgt_idx)
                if e and e.ServerId and e.ServerId ~= 0 then
                    target_set[e.ServerId] = true
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Classifier.  Reads ONLY from state.combatSnap - no native calls,
-- no cross-thread races, no AV risk.  The snapshot is refreshed
-- once per render frame by M.refresh_snapshot() above.
----------------------------------------------------------------------
local function classify_actor_primary(actor_id)
    local snap = state.combatSnap
    if snap.self_id ~= 0 and actor_id == snap.self_id then return M.SCOPE_YOU end
    if snap.pet_id  ~= 0 and actor_id == snap.pet_id  then return M.SCOPE_PET end
    if snap.party_set[actor_id]    then return M.SCOPE_PARTY end
    if snap.alliance_set[actor_id] then return M.SCOPE_ALLIANCE end
    return nil
end

local function is_engaged_target(actor_id)
    return state.combatSnap.target_set[actor_id] == true
end

local function classify_actor(actor_id, target_ids)
    local primary = classify_actor_primary(actor_id)
    if primary then return primary end
    if is_engaged_target(actor_id) then return M.SCOPE_TARGET end
    if target_ids then
        for _, tid in ipairs(target_ids) do
            if classify_actor_primary(tid) then return M.SCOPE_TARGET end
        end
    end
    return M.SCOPE_OTHERS
end

----------------------------------------------------------------------
-- Hierarchy gate.  TARGET always visible; YOU always visible; PET <=
-- level 4; PARTY <= 3; ALLIANCE <= 2; OTHERS only at level 1.
----------------------------------------------------------------------
function M.should_show(scope, level)
    if scope == M.SCOPE_TARGET   then return true        end
    if scope == M.SCOPE_YOU      then return true        end
    if scope == M.SCOPE_PET      then return level <= 4 end
    if scope == M.SCOPE_PARTY    then return level <= 3 end
    if scope == M.SCOPE_ALLIANCE then return level <= 2 end
    if scope == M.SCOPE_OTHERS   then return level <= 1 end
    return true
end

----------------------------------------------------------------------
-- Helpers used by the two per-packet handlers.  Reads from the
-- render-thread snapshot; no native calls.
----------------------------------------------------------------------
local function get_self_id()
    return state.combatSnap.self_id
end

----------------------------------------------------------------------
-- 0x028: action packet.  Modify per-result `message` (and the
-- add_effect / spike_effect message fields) to 0 for any result the
-- filter wants hidden, then write back via e.data_modified.  Keeps
-- animations + damage popups intact.
----------------------------------------------------------------------
local function handle_action_packet(e)
    local source = e.data_modified or e.data
    local act    = string_to_act(source)
    if not act.targets or act.target_count == 0 then return end

    -- Target-ID list passed into classify_actor so it can detect
    -- "this action targets a friendly" (the (c) check) even when
    -- the actor isn't currently locked-on.
    local target_ids = {}
    for i, tg in ipairs(act.targets) do
        target_ids[i] = tg.server_id
    end

    local scope       = classify_actor(act.actor_id, target_ids)
    local level       = allSettings.PacketFilterLevel
    local hide_actor  = not M.should_show(scope, level)
    local me_only     = (scope == M.SCOPE_TARGET)
                        and allSettings.PacketFilterTargetMeOnly[1]
    local self_id     = me_only and get_self_id() or 0

    local touched = false
    for _, tg in ipairs(act.targets) do
        -- Per-target hide decision.  Either the whole actor is
        -- hidden at this level, OR me-only is on and this target
        -- isn't me.
        local hide = hide_actor
        if me_only and not hide and tg.server_id ~= self_id then
            hide = true
        end
        if hide then
            for _, a in ipairs(tg.actions) do
                if a.message ~= 0 then
                    a.message = 0
                    touched = true
                end
                if a.has_add_effect and a.add_effect_message ~= 0 then
                    a.add_effect_message = 0
                    touched = true
                end
                if a.has_spike_effect and a.spike_effect_message ~= 0 then
                    a.spike_effect_message = 0
                    touched = true
                end
            end
        end
    end

    if touched then
        e.data_modified = act_to_string(source, act)
    end
end

----------------------------------------------------------------------
-- Per-packet entry called from lifecycle.lua's existing packet_in.
--
-- Only 0x028 (Action) is treated as combat-relevant - same scope as
-- atom0s' actionparse.  We deliberately do NOT touch 0x029
-- ("orphan action message") because despite the name it carries
-- overwhelmingly NON-combat traffic that the user expects to keep
-- seeing regardless of filter level:
--   - Records of Eminence / RoV progress
--   - /check responses
--   - "You obtain X gil / items"
--   - skillup messages
--   - mission / quest status updates
--   - status-effect wear-off ("you no longer feel the effect of...")
-- A handful of combat-flavored buff wear-offs from strangers may
-- now leak through at high filter levels, but that's a tiny cost
-- compared to silently hiding RoE/RoV progress.
--
-- The 0x028 handler is pcall'd as a defensive net: malformed or
-- unusual-layout action packets (notably spell-interrupt variants -
-- see simplelog PR #19 / issue #26) can leave `target_count` or
-- `action_count` as nil after bit-unpacking, which would error the
-- `for i = 1, n do` loop in string_to_act.  We don't have simplelog's
-- `targets[1].actions[1].message` direct-index crash (we use ipairs
-- which is empty-table-safe), but the nil-numeric-for crash is a
-- real risk.  Any error here leaves e.data_modified untouched so
-- the game receives the original packet - animations and chat both
-- render normally, the filter just opts out for that one packet.
----------------------------------------------------------------------
function M.dispatch(e)
    if not allSettings.PacketFilterEnabled2[1] then return end
    if e.id == 0x028 then
        pcall(handle_action_packet, e)
    end
end

return M
