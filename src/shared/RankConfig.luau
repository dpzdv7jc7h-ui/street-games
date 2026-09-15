local RankConfig = {}

RankConfig.Ranks = {
	{ Name = "Free Agent", RequiredXP = 0 },
	{ Name = "Rookie", RequiredXP = 100 },
	{ Name = "Block Runner", RequiredXP = 300 },
	{ Name = "Member", RequiredXP = 700 },
	{ Name = "Respected", RequiredXP = 1500 },
	{ Name = "Veteran", RequiredXP = 3000 },
	{ Name = "OG", RequiredXP = 6000 },
	{ Name = "Street Legend", RequiredXP = 10000 },
}

function RankConfig.GetRankIndexForXP(xp: number): number
	xp = math.max(0, math.floor(xp))

	for index = #RankConfig.Ranks, 1, -1 do
		if xp >= RankConfig.Ranks[index].RequiredXP then
			return index
		end
	end

	return 1
end

function RankConfig.GetRankForXP(xp: number)
	local index = RankConfig.GetRankIndexForXP(xp)
	return RankConfig.Ranks[index], index
end

function RankConfig.GetProgressForXP(xp: number)
	xp = math.max(0, math.floor(xp))

	local rank, index = RankConfig.GetRankForXP(xp)
	local nextRank = RankConfig.Ranks[index + 1]

	if not nextRank then
		return {
			Rank = rank,
			RankIndex = index,
			NextRank = nil,
			XPIntoRank = math.max(0, xp - rank.RequiredXP),
			XPNeededForRank = 0,
			Progress = 1,
		}
	end

	local span = nextRank.RequiredXP - rank.RequiredXP
	local intoRank = xp - rank.RequiredXP

	return {
		Rank = rank,
		RankIndex = index,
		NextRank = nextRank,
		XPIntoRank = intoRank,
		XPNeededForRank = span,
		Progress = math.clamp(intoRank / span, 0, 1),
	}
end

return RankConfig
