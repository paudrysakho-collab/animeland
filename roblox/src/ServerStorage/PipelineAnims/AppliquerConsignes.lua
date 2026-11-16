-- Outil d'édition (synchro dépôt / Studio) : applique un fichier de consignes JSON {chemin: [[ancien, nouveau], ...]}
-- (toutes les occurrences, comme mission/consignes/appliquer.py) et renvoie la somme Adler « taille:somme » de chaque script.
local HttpService = game:GetService("HttpService")
local function trouver(chemin)
	local o = game
	for seg in chemin:gmatch("[^/]+") do
		seg = seg:gsub("%.server%.lua$", ""):gsub("%.client%.lua$", ""):gsub("%.lua$", "")
		o = o:FindFirstChild(seg)
		if not o then
			return nil
		end
	end
	return o
end
local function adler(s)
	local a, b = 1, 0
	for i = 1, #s do
		a = (a + s:byte(i)) % 65521
		b = (b + a) % 65521
	end
	return #s .. ":" .. (b * 65536 + a)
end
local function remplacerTout(t, old, new)
	local n, pos, res = 0, 1, {}
	while true do
		local i, j = string.find(t, old, pos, true)
		if not i then
			break
		end
		table.insert(res, t:sub(pos, i - 1))
		table.insert(res, new)
		pos = j + 1
		n += 1
	end
	table.insert(res, t:sub(pos))
	return table.concat(res), n
end
return function(json, sommesSeulement)
	local cons = HttpService:JSONDecode(json)
	local out = {}
	for chemin, reps in pairs(cons) do
		local s = trouver(chemin)
		if not s then
			return "ABSENT " .. chemin
		end
		local t = s.Source
		if not sommesSeulement then
			for _, r in ipairs(reps) do
				local n
				t, n = remplacerTout(t, r[1], r[2])
				if n == 0 then
					return "INTROUVABLE " .. chemin .. " : " .. r[1]:sub(1, 60)
				end
			end
			s.Source = t
		end
		table.insert(out, chemin .. " " .. adler(t))
	end
	return table.concat(out, "\n")
end
