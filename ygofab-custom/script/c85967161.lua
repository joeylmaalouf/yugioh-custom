-- Aromaseraphy Bergamot
local s, id = GetID()

function s.initial_effect (c)
	-- must be properly summoned before reviving
	c:EnableReviveLimit()
	-- needs exactly 3 Plant materials
	Link.AddProcedure(c, aux.FilterBoolFunctionEx(Card.IsRace, RACE_PLANT), 3, 3)

	-- effect 1: if ahead in LP, gain attack equal to the difference
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.attack_condition)
	e1:SetValue(s.attack_value)
	c:RegisterEffect(e1)

	-- effects 2/3: gain LP on pointed-to normal or special summon
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_TRIGGER_F + EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(aux.zptcon(Card.IsFaceup))
	e2:SetOperation(s.recover_operation)
	c:RegisterEffect(e2)
	local e3 = e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

-- this card should only gain attack if its owner is ahead in LP
function s.attack_condition (e)
	local tp = e:GetHandlerPlayer()
	return Duel.GetLP(tp) > Duel.GetLP(1 - tp)
end

-- the amount gained should be equal to the difference
function s.attack_value (e, c)
	local tp = e:GetHandlerPlayer()
	return Duel.GetLP(tp) - Duel.GetLP(1 - tp)
end

-- the controller of this card should gain LP if the conditions are met
function s.recover_operation (e, tp, eg, ep, ev, re, r, rp)
	Duel.Recover(e:GetHandlerPlayer(), 1000, REASON_EFFECT)
end
