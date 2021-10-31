-- Blood Lord Vampire Varney
local s, id = GetID()

function s.initial_effect (c)
	-- must be properly summoned before reviving
	c:EnableReviveLimit()
	-- needs 2+ level 7 materials
	Xyz.AddProcedure(c, nil, 7, 2, nil, nil, 99)

	-- effect 1: treat potential materials as a valid level
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE + EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_XYZ_LEVEL)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetTargetRange(LOCATION_MZONE, 0)
	e1:SetTarget(s.level_target)
	e1:SetValue(s.level_value)
	c:RegisterEffect(e1)

	-- effect 2: detach 2 if lower LP to gain difference
	local e2 = Effect.CreateEffect(c)	
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.recover_condition)
	e2:SetCost(s.recover_cost)
	e2:SetOperation(s.recover_operation)
	c:RegisterEffect(e2)
end

-- any card with a level of 1+ that originally belonged to the opponent is valid for level adjustment
function s.level_target (e, c)
	return c:IsLevelAbove(1) and c:GetOwner() ~= e:GetHandlerPlayer()
end

-- if the card is affected by the level modulation targeting, then we can treat it as 7
function s.level_value (e, c, rc)
	local lv = c:GetLevel()
	if rc:IsCode(id) then return 7
	else return lv end
end

-- the LP gain effect can only be used if this card's player has less LP than the opponent
function s.recover_condition (e, tp, eg, ep, ev, re, r, rp)
	return Duel.GetLP(tp) < Duel.GetLP(1 - tp)
end

-- the cost is to detach exactly 2 materials
function s.recover_cost (e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return e:GetHandler():CheckRemoveOverlayCard(tp, 2, REASON_COST)
	end
	e:GetHandler():RemoveOverlayCard(tp, 2, 2, REASON_COST)
end

-- the effect is to gain the difference in LP
function s.recover_operation (e, tp, eg, ep, ev, re, r, rp)
	Duel.Recover(tp, Duel.GetLP(1 - tp) - Duel.GetLP(tp), REASON_EFFECT)
end
