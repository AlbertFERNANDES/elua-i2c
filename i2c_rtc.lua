-- I2C RTC functions for eLua, on GitHub
-- 15/01/2014, by Albert FERNANDES

-- this code need driver i2c, named i2c.lua
-- can easy modify for others RTC's CI

--PCF8583				=	160

--Address Registers:
--00: control/status
--01
--02: seconds
--03
--04 hours. b7 a 0 : format 24h
--05 DATE.
--06 days of the week: b5,b6,b7 + months
--07

reg_rtc_years	=	16 --register free, used for storage year !
reg_rtc_months	=	6
reg_rtc_days	=	5
reg_rtc_hours	=	4
reg_rtc_minutes	=	3
reg_rtc_minutes	=	2

ad_rtc = 160 -- address of PCF8583
A0     = 0 -- pin A0 at vdd, if at GND=2

require("i2c.lua")
----------------------------------------------------------------------------------------
function init_rtc_I2C( address ) -- init RTC
	start_I2C()
	send_byte_I2C( address, 0 )	--register 0
	ack_I2C( address )
	send_byte_I2C( 0 )			--value register control/status, reg0
	stop_I2C()
end
----------------------------------------------------------------------------------------
function bcdtodec( value ) --convert BCD value in decimal, on 2 digits
	local copie, depart
	depart	=	tonumber( value )
	copie	=	bit.band( depart, 240 )
	copie	=	copie/16
	depart	=	bit.band( depart, 15 )
	copie	=	copie * 10 + depart
	return string.format( "%02d", copie )
end
----------------------------------------------------------------------------------------
function dectobcd( value ) --convert decimal value in BCD. Max value in: 99
	local qpfaible, qpfort
	if value < 10 then
		return value
	else
		value = tostring( value )
		--
		qpfaible	=	string.sub( value, 2, 2 ) 	--
		qpfort		=	string.sub( value, 1, 1 )		--
		qpfort		=	bit.lshift( tonumber( qpfort), 4 )
		value		=	qpfort + tonumber( qpfaible )
		return value
	end
end
----------------------------------------------------------------------------------------
function set_hours_I2C( address, hours )
	start_I2C()
	write_register_I2C( address, reg_rtc_hours, dectobcd( hours ))
	stop_I2C()
end
----------------------------------------------------------------------------------------
function set_minutes_I2C( minutes )
	start_I2C()
	write_register_I2C( address, reg_rtc_minutes, dectobcd( minutes ))
	stop_I2C()
end
----------------------------------------------------------------------------------------
function set_seconds_I2C( seconds )
	start_I2C()
	write_register_I2C(address, reg_rtc_seconds, dectobcd( seconds ))
	stop_I2C()
end
----------------------------------------------------------------------------------------
function set_ans_I2C( years )
	start_I2C()
	write_register_I2C( address, reg_rtc_years, dectobcd( years ))
	stop_I2C()
end
----------------------------------------------------------------------------------------
function get_hours_I2C()--retourne la variable heure ! TRAITEMENT SPECIAL
	local hours
	start_I2C()
	hours		=	bintodec(read_register_I2C( address, reg_rtc_hours ))
	stop_I2C()
	return string.format("%02d", bcdtodec( hours ))
end
----------------------------------------------------------------------------------------
function get_minutes_I2C()
	local minutes
	start_I2C()
	minutes		=	bintodec(read_register_I2C( address, reg_rtc_minutes ))
	stop_I2C()
	return string.format( "%02d", bcdtodec( minutes ))
end
----------------------------------------------------------------------------------------
function get_seconds_I2C()
	local seconds
	start_I2C()
	seconds	=	bintodec(read_register_I2C( address, reg_rtc_seconds ))
	stop_I2C()
	return string.format( "%02d", bcdtodec( seconds ))
end
----------------------------------------------------------------------------------------
function get_days_I2C()
	local days
	start_I2C()
	days	=	bintodec(read_register_I2C( address, reg_rtc_days ))
	stop_I2C()
	return string.format( "%02d", bcdtodec( days ))
end
----------------------------------------------------------------------------------------
function get_months_I2C()--TRAITEMENT SPECIAL!
	local months, day_week
	start_I2C()
	months = read_register_I2C( address, reg_rtc_months)
	stop_I2C()
	--on a les 5 bits de poid faible pour le mois, et les 3 bits de poid fort pour le jour de la semaine
	day_week = bit.rshift( months, 5 )--deplace les 3 bits de poid fort a droite
	day_week = bit.band( day_week, 7 )--recup des 3 bits de poid faible
	months   = bit.band( months, 31 )--recup les 5 bits de poid faible
	return string.format( "%02d", bcdtodec( months ) ), day_week
end
----------------------------------------------------------------------------------------
function get_year_I2C()--TRAITEMENT SPECIAL! UTILISE UNE ADRESSE LIBRE EN RAM POUR STOCKER L'ANNEE
	local years
	start_I2C()
	years	=	bintodec(read_register_I2C( address, reg_rtc_years ))
	--months = read_register_I2C( address, 6 )
	stop_I2C()
	return string.format( "20%02d", bcdtodec( years ))
end
----------------------------------------------------------------------------------------
