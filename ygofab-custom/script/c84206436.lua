-- The Frozen Barrier
local s, id = GetID()

function s.initial_effect (c)
	-- always treated as an "Ice Barrier" card
	c:AddSetcodesRule(0x2f)
	-- can hold Ice Counters
	c:EnableCounterPermit(0x1015)

	-- effect 1: card activation
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- effects 2/3: ATK/DEF boost for matching monsters
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	e2:SetTarget(s.stat_target)
	e2:SetValue(600)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)

	-- effect 4/5: counter gain from opponent card effect destruction/banishment
	local e4 = Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_CONTINUOUS + EFFECT_TYPE_FIELD)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetRange(LOCATION_FZONE)
	e4:SetOperation(s.counter_operation)
	c:RegisterEffect(e4)
	local e5 = e4:Clone()
	e5:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e5)

	-- effect 6: "Ice Barrier" monster protection based on counter count
	local e6 = Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetRange(LOCATION_FZONE)
	e6:SetTargetRange(LOCATION_MZONE, 0)
	e6:SetTarget(s.immunity_target)
	e6:SetValue(s.immunity_filter)
	c:RegisterEffect(e6)
end

s.listed_series = {0x2f}
s.counter_place_list = {0x1015}

-- only water warriors and water spellcasters should get the stat boost
function s.stat_target (e, c)
	return c:IsAttribute(ATTRIBUTE_WATER) and (c:IsRace(RACE_WARRIOR) or c:IsRace(RACE_SPELLCASTER))
end

-- filter to your "Ice Barrier" monsters that have been acted on by an opponent's card effect
function s.counter_filter (c, tp)
	return
		c:IsControler(tp)
		and c:IsSetCard(0x2f)
		and c:IsType(TYPE_MONSTER)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:GetReasonPlayer() == 1 - tp
		and c:IsReason(REASON_EFFECT)
end

-- add Ice Counters equal to the number of valid targets
function s.counter_operation (e, tp, eg, ep, ev, re, r, rp)
	local ct = eg:FilterCount(s.counter_filter, nil, tp)
	if ct > 0 then
		e:GetHandler():AddCounter(0x1015, ct * 2)
	end
end

-- the only monsters that should be immune are your "Ice Barrier" monsters with a level <= the number of Ice Counters on this card
function s.immunity_target (e, c)
	return
		c:IsControler(e:GetHandlerPlayer())
		and c:IsSetCard(0x2f)
		and c:IsType(TYPE_MONSTER)
		and c:GetLevel() > 0
		and c:GetLevel() <= e:GetHandler():GetCounter(0x1015)
end

-- the only effects your cards should be immune to are ones belonging to your opponent
function s.immunity_filter (e, re)
	return re:GetOwnerPlayer() == 1 - e:GetHandlerPlayer()
end
