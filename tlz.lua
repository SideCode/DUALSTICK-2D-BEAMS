local tlz = {}

function tlz.clearTable(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

function tlz.HSL2RGB(hue,sat,lum,a)
	local c = (1 - math.abs(2 * lum - 1)) * sat
	local h = hue/60
	local x = c * (1 - math.abs(h % 2 - 1))
	local m = lum - 0.5 * c
	
	c = c + m
	x = x + m
	
	c = c * 255
	x = x * 255
	m = m * 255
	
	h = math.floor(h + 1)
	
	local r = {c,x,m,m,x,c}
	local g = {x,c,c,x,m,m}
	local b = {m,m,x,c,c,x}

	return {r[h],g[h],b[h],a and a*255 or 255}
end

function tlz.flipDir(dir,xf,yf)
	dir = math.rad(dir)
	dir = math.atan2(math.sin(dir) * yf,math.cos(dir) * xf)
	return math.deg(dir)
end

function tlz.c2c(x1,y1,r1,x2,y2,r2)
	local x = x2 - x1
	local y = y2 - y1
	local r = r1 + r2
	if(x*x + y*y < r^2)then
		return r - (x*x + y*y)^0.5, math.atan2(y,x)
	end
	
	return false,false
end

function tlz.l2c(x1,y1,dir,x2,y2,r2)
	local x = x2 - x1
	local y = y2 - y1
	
	local xr = x * math.cos(-dir) - y * math.sin(-dir)
	local yr = x * math.sin(-dir) + y * math.cos(-dir)
	
	if(math.abs(yr) <= r2 and xr >= -r2)then
		return xr,yr
	end
	
	return false,false
end

function tlz.aInArc(dv,v1,v2)
	local dv = dv % math.rad(360)
	local v1 = v1 % math.rad(360)
	local v2 = v2 % math.rad(360)
	
	if(v2 < v1)then
		return v1 <= dv or dv <= v2
	end
	
	return v1 <= dv and dv <= v2
end

function tlz.bound(dx,dy,x1,x2,y1,y2)
	local bx = 0
	local by = 0
	
	if(dx < x1)then
		dx = x1
		bx = -1
	elseif(dx > x2)then
		dx = x2
		bx = 1
	end
	
	if(dy < y1)then
		dy = y1
		by = -1
	elseif(dy > y2)then
		dy = y2
		by = 1
	end
	
	return dx,dy,bx,by
end

return tlz