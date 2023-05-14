local function fig(a,rots)
	local t={}
	local mx,my=-1,-1
	local x,y=0,0
	a:gsub(".",function(a)
		if a=="\n" then
			x=0
			y=y+1
		elseif a==" " then
			mx,my=math.max(x,mx),math.max(y,my)
			x=x+1
		else
			mx,my=math.max(x,mx),math.max(y,my)
			t[#t+1]={x,y}
			x=x+1
		end
	end)
	t.w,t.h=mx+1,my+1
	t.rots=rots
	for k,v in ipairs(t) do
		v[2]=(t.h-1)-v[2]
	end
	return t
end
local function L()
	local rope={}
	local function f(a)
		if not a then return table.concat(rope,"\n") end
		rope[#rope+1]=a
		return f
	end
	return f
end
local rots={
	wiggly={
		{{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},},
		{{ 0, 0},{ 1, 0},{ 1,-1},{ 0, 2},{ 1, 2},},
		{{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},{ 0, 0},},
		{{ 0, 0},{-1, 0},{-1,-1},{ 0, 2},{-1, 2},},
	},
	stick={
		{{ 0, 0},{-1, 0},{ 2, 0},{-1, 0},{ 2, 0},},
		{{-1, 0},{ 0, 0},{ 0, 0},{ 0, 1},{ 0,-2},},
		{{-1, 1},{ 1, 1},{-2, 1},{ 1, 0},{-2, 0},},
		{{ 0, 1},{ 0, 1},{ 0, 1},{ 0,-1},{ 0, 2},}
	},
	cube={
		{{ 0, 0},},
		{{ 0,-1},},
		{{-1,-1},},
		{{-1, 0},},
	}
}
local figs={
	fig(L()
		"     "
		"     "
		" ...."
		"     "
		"     "(
	),rots.stick),
	fig(L()
		".  "
		"..."
		"   "(
	),rots.wiggly),
	fig(L()
		"  ."
		"..."
		"   "(
	),rots.wiggly),
	fig(L()
		" .."
		" .."
		"   "(
	),rots.cube),
	fig(L()
		" .."
		".. "
		"   "(
	),rots.wiggly),
	fig(L()
		" . "
		"..."
		"   "(
	),rots.wiggly),
	fig(L()
		".. "
		" .."
		"   "(
	),rots.wiggly),
}
for k,v in pairs(figs) do
	local figs,figsl={v},figs
	for n=2,4 do
		local fb=figs[n-1]
		local fig={w=fb.w,h=fb.h,rots=fb.rots}
		for k,v in ipairs(fb) do
			fig[#fig+1]={v[2],(fb.w-1)-v[1]}
		end
		figs[n]=fig
	end
	figsl[k]=figs
end
local colors={
	[0]={0.5,0.5,0.5},
	{0,1,1},
	{0,0,1},
	{1,.5,0},
	{1,1,0},
	{0,1,0},
	{1,0,1},
	{1,0,0},
}
local function apply(a,f)
	local b={}
	for k,v in ipairs(a) do b[k]=f(v) end
	return b
end
for k,v in pairs(colors) do
	colors[k]={apply(v,function(a)
		return a*0.9
	end),apply(v,function(a)
		return a*0.5
	end)}
end
local function sign(a)
	return a>0 and 1 or (a<0  and -1 or 0)
end
local function interp(a,b,dt)
	return a+sign(b-a)*math.min((b-a)*sign(b-a),math.max(dt,(b-a)*sign(b-a)*math.max(dt,0.01)*10))
end
local function lerpc(a,b,t)
	local r=a[1]*(1-t)+b[1]*t
	local g=a[2]*(1-t)+b[2]*t
	local b=a[3]*(1-t)+b[3]*t
	return r,g,b
end
local newgame
do
	local game={}
	game.__index=game
	local W,H=10,20
	function newgame()
		local self=setmetatable({},game)
		self.board={}
		for y=1,H do
			self.board[y]={off=0}
		end
		self.nextfig={math.random(1,#figs),math.random(1,4)}
		self:espawn()
		return self
	end
	function game:espawn()
		if self.fig then
			for k,v in ipairs(figs[self.fig[1]][self.fig[2]]) do
				local x,y=self.cfx+v[1],math.ceil(self.cfy)+v[2]
				if self.board[y] then
					self.board[y][x]=self.fig[1]
				else
					self.over=0
				end
			end
		end
		if self.over then return end
		self.fig=self.nextfig
		self.nextfig={math.random(1,#figs),math.random(1,4)}
		self.cfmx=W+1-figs[self.fig[1]][self.fig[2]].w
		self.cfx=math.random(1,self.cfmx)
		self.cfy=H+1
		self.cfdx=self.cfx
	end
	function game:move(a)
		local s=sign(a)
		local mov=false
		for a=s,a,s do
			self.cfx=self.cfx+s
			local ccy=math.ceil(self.cfy)
			local cfy=math.floor(self.cfy)
			local cccy=self:collide(self.cfx,ccy)
			local ccfy=self:collide(self.cfx,cfy)
			if ccfy and not cccy then
				self.cfy=ccy
			elseif cccy and not ccfy then
				self.cfy=cfy
			elseif ccfy and cccy then
				self.cfx=self.cfx-s
				break
			end
			mov=true
		end
		if mov then
			self.colt=nil
		end
	end
	function game:spin(a)
		local ofig=self.fig
		self.fig={ofig[1],(ofig[2]-1+a)%4+1}
		local mov=false
		local rots=figs[self.fig[1]][self.fig[2]].rots
		for k,v in ipairs(rots[ofig[2]]) do
			local ccy=math.ceil(self.cfy)
			local cfy=math.floor(self.cfy)
			local ox,oy=v[1]-rots[self.fig[2]][k][1],v[2]-rots[self.fig[2]][k][2]
			local cccy=self:collide(self.cfx+ox,ccy+oy)
			local ccfy=self:collide(self.cfx+ox,cfy+oy)
			local good=true
			local ncfy=self.cfy+oy
			if ccfy and not cccy then
				ncfy=ccy+oy
			elseif cccy and not ccfy then
				ncfy=cfy+oy
			elseif ccfy and cccy then
				good=false
			end
			if good then
				mov=true
				self.colt=nil
				local ocx,ocy=self.cfx,self.cfy
				self.cfx=self.cfx+ox
				self.cfy=ncfy
				break
			end
		end
		if not mov then
			self.fig=ofig
		end
	end
	function game:drawcell(x,y,fig)
		if not fig then return end
		love.graphics.push("all")
		love.graphics.translate((x-1),H-(y))
		love.graphics.setColor(lerpc(colors[fig][2],colors[0][2],self.over or 0))
		love.graphics.rectangle("fill",0,0,1,1)
		love.graphics.setColor(lerpc(colors[fig][1],colors[0][1],self.over or 0))
		love.graphics.rectangle("fill",0.1,0.1,0.8,0.8)
		love.graphics.pop()
	end
	function game:drawfig(x,y,fig)
		for k,v in ipairs(figs[fig[1]][fig[2]]) do
			self:drawcell(x+v[1],y+v[2],fig[1])
		end
	end
	function game:collide(x,y)
		for k,v in ipairs(figs[self.fig[1]][self.fig[2]]) do
			local x,y=x+v[1],y+v[2]
			if x<1 or x>W or y<1 or (self.board[y] and self.board[y][x]) then
				return true
			end
		end
	end
	function game:update(dt,fast)
		if self.over then
			self.over=interp(self.over,1,dt/4)
			return
		end
		self.cfy=self.cfy-dt*4*(self.fast and 8 or 1)
		local ry=math.ceil(self.cfy)
		if self:collide(self.cfx,ry-1) then
			self.cfy=ry
			self.colt=(self.colt or 0.5)-dt
		else
			self.colt=nil
		end
		if self.colt and self.colt<=0 then
			self:espawn()
		end
		self.cfdx=interp(self.cfdx,self.cfx,dt*4)
		for y=1,H do
			self.board[y].off=interp(self.board[y].off,0,dt)
			local good=true
			for x=1,W do
				good=good and self.board[y][x]
			end
			if good then
				table.remove(self.board,y)
				self.board[y].off=self.board[y].off+1
				self.board[#self.board+1]={off=0}
			end
		end
	end
	function game:draw(x,y,w,h)
		love.graphics.push("all")
			love.graphics.translate(x,y)
			love.graphics.scale(w,h)
			love.graphics.stencil(function()
				love.graphics.rectangle("fill",0,0,1,1)
			end)
			love.graphics.setStencilTest("greater",0)
			love.graphics.push("all")
				love.graphics.translate(0.5,0)
				love.graphics.scale(1/H)
				love.graphics.translate(-W/2,0)
				love.graphics.setColor(0.1,0.1,0.1)
				love.graphics.rectangle("fill",0,0,W,H)
				local off=0
				for y=1,H do
					off=off+self.board[y].off
					for x=1,W do
						self:drawcell(x,y+off,self.board[y][x])
					end
				end
				if not self.over then
					self:drawfig(self.cfdx,self.cfy,self.fig)
					love.graphics.translate(W+2.5,H/2)
					local ox,oy=(5-figs[self.nextfig[1]][self.nextfig[2]].w)/2,(5-figs[self.nextfig[1]][self.nextfig[2]].h)/2
					self:drawfig(-1.5+ox,H-1.5+oy,self.nextfig)
				end
			love.graphics.pop()
		love.graphics.pop()
	end
end

local game

local keys={
	left={
		left=true,a=true
	},
	right={
		right=true,d=true
	},
	sccw={
		q=true
	},
	scw={
		e=true
	},
	down={
		down=true,s=true
	},
	sneak={
		lshift=true,rshift=true
	},
}

local function isdown(k)
	for k,v in pairs(k) do
		if love.keyboard.isDown(k) then
			return true
		end
	end
end

function love.load()
	game=newgame()
	love.keyboard.setKeyRepeat(true)
end

function love.keypressed(key)
	if keys.left[key] or keys.right[key] then
		local a=keys.left[key] and -1 or 1
		if isdown(keys.sneak) then
			game:spin(a)
		else
			game:move(a)
		end
	elseif keys.scw[key] or keys.sccw[key] then
		local a=keys.sccw[key] and -1 or 1
		game:spin(a)
	end
end

function love.update(dt)
	game.fast=isdown(keys.down)
	game:update(dt)
end

function love.draw()
	local w,h=love.graphics.getDimensions()
	local a=math.min(w,h)
	local x,y=(w-a)/2,(h-a)/2
	game:draw(x,y,a,a)
end

