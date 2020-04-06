function math.Percent(num, perc)	--stfu
	perc = perc / 100
	return num * perc
end

--two if's are faster than math sqrt addition multiplication bullshit, dont @ me
--(its not for rotated shit)

function math.PointIn2DBox(px, py, rx, ry, rw, rh)


	local cond1 = (rx < px) and (px < rx + rw)	--X
	if not cond1 then return false end

	local cond2 = (ry < py) and (py < ry + rh)	--Y
	if not cond2 then return false end

	return true
end

function bit.bool(bool)
	return bool and 1 or 0
end

--why no 64bit bitops wtf mike
--these are not good, shut up

function bit.biglshift(num, amt)
	return num * 2^amt
end

function bit.bigrshift(num, amt)
	local n2 = num / 2^amt
	return n2 - n2 % 1
end

--there was a string->num and num->string but i gave up here