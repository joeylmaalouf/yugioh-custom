-- Dark World Vengeance
local s, id = GetID()

function s.initial_effect(c)
	-- activate without using the effect
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- activate and use the effect immediately
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)

	-- use the effect sometime later, after activation
	local e3 = e2:Clone()
	e3:SetType(EFFECT_TYPE_TRIGGER_O)
	e3:SetRange(LOCATION_SZONE)
	c:RegisterEffect(e3)
end
s.listed_series = {0x6}

-- check whether the card that triggered the destroyed event is exactly 1 of your face-up Dark World monsters
function s.condition (e, tp, eg, ep, ev, re, r, rp)
	local tc = eg:GetFirst()
	return #eg == 1 and tc:IsReason(REASON_DESTROY) and tc:IsPreviousLocation(LOCATION_MZONE) and tc:IsPreviousControler(tp) and tc:IsSetCard(0x6)
end

-- if it is, tell the game that we're going to be discarding it
function s.target (e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chk == 0 then return true end
	local g = eg:GetFirst()
	Duel.SetOperationInfo(0, CATEGORY_HANDES, g, #g, 0, 0)
end

-- so now we can discard the monster instead of letting it be destroyed
function s.operation (e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	-- if this card has been somehow invalidated, stop here
	if not c:IsRelateToEffect(e) then return end
	-- otherwise, get the target card (not target-keyword target, but the one we noted in s.target above)
	local tc = Duel.GetFirstTarget()
	-- if the monster is still usable, we can finally discard it
	if tc:IsRelateToEffect(e) then
		Duel.SendtoGrave(tc, REASON_EFFECT + REASON_DISCARD)
	end
end
