-- Gravity Well
local s, id = GetID()

function s.initial_effect (c)
	-- effect 1: card activation
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	-- effect 2: attack prevention
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE, LOCATION_MZONE)
	e2:SetTarget(s.target)
	c:RegisterEffect(e2)
end

-- we specifically only want this to apply to monsters with Xyz rank 4+ or Link rating 2+
-- the rest are covered by normal Gravity Bind
function s.target (e, c)
	return c:GetRank() >= 4 or c:GetLink() >= 2
end
