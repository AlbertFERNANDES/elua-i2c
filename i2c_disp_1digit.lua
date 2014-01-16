-- I2C functions for eLua, on GitHub
-- 15/01/2014, by Albert FERNANDES

-- this code need driver i2c, named i2c.lua


--[[
Sample for drive display single digit by PCF8574

in display single digit like SA39, SC39:
a   = P0 of PCF8574
b   = P1 of PCF8574
c   = P2 of PCF8574
d   = P3 of PCF8574
e   = P4 of PCF8574
g   = P5 of PCF8574
f   = P6 of PCF8574
dot = P7 of PCF8574

]]

require("i2c.lua")

disp_i2c = {}   -- code' table
disp_i2c[0]=63  -- all -g is ON (-dot)
disp_i2c[1]=6   -- b+c is ON (-dot)
disp_i2c[2]=91  -- a+b+d+e+g is ON (-dot)
disp_i2c[3]=79  -- all -ef is ON (-dot)
disp_i2c[4]=102 -- b+c+f+g is ON (-dot)
disp_i2c[5]=109 -- all -be is ON (-dot)
disp_i2c[6]=125 -- all -b is ON (-dot)
disp_i2c[7]=7   -- a+b+c is ON (-dot)
disp_i2c[8]=127 -- all is ON (-dot)
disp_i2c[9]=111 -- all -e is ON  (-dot)

disp_i2c["."]=128 --dot.
disp_i2c["A"]=119
disp_i2c["B"]=124
disp_i2c["C"]=57
disp_i2c["D"]=94
disp_i2c["E"]=121
disp_i2c["F"]=113
disp_i2c["H"]=118
disp_i2c["L"]=56
disp_i2c["P"]=115
disp_i2c["U"]=62
disp_i2c["Y"]=110

----------------------------------------------------------------------------------------
function chenillard(address) -- for fun only!
	local i=1
	while true do
		start_I2C()
		write_byte_I2C(address,i)	--0
		stop_I2C()
		tmr.delay(0,80000)
		if i==32 then
			i=1
		else
			i=i*2
		end
	end
end
----------------------------------------------------------------------------------------
