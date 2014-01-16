-- I2C functions for eLua, on GitHub
-- 15/01/2014, by Albert FERNANDES

i2c_Read  = 1
i2c_Write = 0
i2c_retry = 10 -- number retry for ack by slave

SDA = pio.PB_9 -- pin data
SCL = pio.PB_8 -- pin clock

--[[
Use for PCF8574, i/o expander 8 ports:
A2A1A0   = ----111- (if all at VDD)
address  = 0100----
bit_R    = -------1
bit_W    = -------0

ini_i2c()                                     -> config pins
start_i2c()                                   -> start bus, busy
write_byte_i2c(address + A2A1A0 + bit_W, 255) -> all pins ON, output 
stop_i2c()                                    -> stop bus, free

]]

----------------------------------------------------------------------------------------
function bintodec(databin) -- convert a string 'binary' (len: 1 to x) on integer value
	local datadec = 0
	local i
	databin = string.reverse( databin )
	for i = 1, #databin do
		if string.sub( databin, i, i ) == "1" then
			datadec = datadec + ( 2^( i-1 ) )
		end
	end
	return datadec -- return a integer value only!
end
------------------------------------------------------------------------------------
function dectobin( datadec, nbit, reverse ) -- data: integer value, nbit: number of bits for converse (1 to 'n'), reverse: for reverse big or little endian
	local data = ""
	for i=0,nbit-1 do
		if bit.band( datadec, 2^i ) > 0 then data = "1"..data else data = "0"..data end
	end
	if reverse == 1 then
		return string.reverse( data ) 
	else
		return data  -- return string  with '0' & '1'
	end
end
----------------------------------------------------------------------------------------
function ini_I2C()--ini du bus I2C
	pio.pin.setdir(pio.OUTPUT, SCL, SDA)
	pio.pin.sethigh(SCL, SDA)
	-- SDA et SCL a l'etat haut
	-- bus libre
end
----------------------------------------------------------------------------------------
function start_I2C()--condition de start
	-- au depart, le bus est libre: les 2 lignes sont a 1
	-- faire descendre SDA puis SCL
--	pio.pin.setlow( SDA )
--	pio.pin.setlow( SCL )
	pio.pin.setlow(SCL, SDA)
	-- SDA et SCL a l'etat bas
	-- le bus est occupe!
end
----------------------------------------------------------------------------------------
function re_start_I2C()--condition de start
	-- le bus est occupe, les 2 lignes sont a 0
	-- faire monter SCL puis SCL
--	pio.pin.sethigh( SCL )
--	pio.pin.sethigh( SDA )
--	pio.pin.setlow( SDA )
--	pio.pin.setlow( SCL )
	pio.pin.sethigh(SCL, SDA)
	pio.pin.setlow(SCL, SDA)	
	-- le bus est occupe
end
----------------------------------------------------------------------------------------
function stop_I2C()--condition de stop
	-- le bus est occupe, les 2 lignes sont a 0
	-- faire monter SCL puis SDA
--	pio.pin.sethigh( SCL )
--	pio.pin.sethigh( SDA )
	pio.pin.sethigh(SCL, SDA)
	-- le bus est libre, les 2 lignes sont a 1
end
----------------------------------------------------------------------------------------
function write_bit1_I2C()
	-- le bus est occupe, les 2 lignes sont a 0
	-- SCL a 1 + SDA a 1
--	pio.pin.sethigh( SDA )
--	pio.pin.sethigh( SCL )
--	pio.pin.setlow( SCL )
--	pio.pin.setlow( SDA )
	pio.pin.sethigh(SCL, SDA)
	pio.pin.setlow(SCL, SDA)	
	-- SDA et SCL a l'etat bas
	-- bus occupe
end
----------------------------------------------------------------------------------------
function write_bit0_I2C()
	-- le bus est occupe, les 2 lignes sont a 0
	-- SCL a 1 + SDA a 1
	pio.pin.sethigh( SCL )
	pio.pin.setlow( SCL )
	-- SDA et SCL a l'etat bas
	-- bus occupe
end
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
function ack_I2C( address )
	-- reception bit d'acquittement
	local i = 0
	pio.pin.setdir( pio.INPUT, SDA )			--place SDA en entree pour read de l'ACK par l'eSCLave
	pio.pin.sethigh( SCL )					--place SCL a 1
	while true do
		if pio.pin.getval( SDA ) == 0 then	--si SDA est ACK (etat bas par l'eSCLave)
--			pio.pin.setlow( SCL )				--place SCL a 0
--			pio.pin.setlow( SDA )				--place SCL a 0
			pio.pin.setlow( SCL, SDA )	
			pio.pin.setdir( pio.OUTPUT, SDA )	--place SDA en sortie
			return true 					--termine, on passe au suivant
		else
			i = i+1
		end
		if i >= i2c_retry then				--si n retry passe
			pio.pin.setdir( pio.OUTPUT, SDA )	--re place SDA en sortie
--			pio.pin.setlow( SDA )				--place SCL a 0
--			pio.pin.setlow( SCL )				--place SCL a 0
			pio.pin.setlow( SCL, SDA )	
			--print("pas d'acquittement de "..address)
			return false
		end
	end
end
----------------------------------------------------------------------------------------
function send_byte_I2C( value ) -- send 1 byte on I2C bus
	local value, i
	value	=	dectobin( value, 8, 0)
	for i=1,8 do
		if string.sub( value,i,i ) == "1" then
			write_bit1_I2C()
		else
			write_bit0_I2C()
		end
	end
end
----------------------------------------------------------------------------------------
function write_register_I2C( address, register, value ) -- write a value in register at slave address
	send_byte_I2C( address + i2c_Write )		
	ack_I2C( address + i2c_Write )
	send_byte_I2C( register )				
	ack_I2C( address + i2c_Write )
	send_byte_I2C( value )		
	ack_I2C( address + i2c_Write )
end
----------------------------------------------------------------------------------------
function read_register_I2C( address, register ) -- read value of register at slave address
	local value = ""
	local read_SDA, i
	
	send_byte_I2C( address + i2c_Write )		-- send slave address
	ack_I2C( address + i2c_Write )
	
	send_byte_I2C( register )					-- send register
	ack_I2C( address + i2c_Write )
	re_start_I2C()	
	send_byte_I2C( address + i2c_Read )		--re-send slave address
	
	if ack_I2C( address + i2c_Read ) then
		pio.pin.setdir( pio.INPUT, SDA )
		for i = 1, 8 do		
			pio.pin.sethigh( SCL )
			read_SDA = pio.pin.getval( SDA )
			if read_SDA == 0 then		
				value = value.."0"
			else
				value = value.."1"
			end
			pio.pin.setlow( SCL )
		end
		pio.pin.setdir( pio.OUTPUT, SDA )
		pio.pin.setlow( SDA )				
	end
	pio.pin.sethigh( SCL ) -- ACK Master
	pio.pin.setlow( SCL )
	return value
end
----------------------------------------------------------------------------------------
function read_byte_I2C( address ) -- read a byte on I2C
	local value = ""
	local read_SDA, i
	send_byte_I2C( address + i2c_read ) -- send address byte
	if ack_I2C( address + i2c_read ) then -- ACK OK?
		pio.pin.setdir( pio.INPUT, SDA )
		for i=1,8 do		-- 8 clocks reading
			pio.pin.sethigh( SCL )
			read_SDA = pio.pin.getval( SDA )
			if read_SDA == 0 then		
				value = value.."0"
			else
				value = value.."1"
			end
			pio.pin.setlow( SCL )
		end
		pio.pin.setdir( pio.OUTPUT, SDA )
		pio.pin.setlow( SDA )			
	end
	return value
end
----------------------------------------------------------------------------------------
function write_byte_I2C( address, value )-- send 1 single order on I2C bus
	send_byte_I2C( address + i2c_write )
	while ack_I2C( address + i2c_write ) do
		send_byte_I2C( value )
		break
	end
end
