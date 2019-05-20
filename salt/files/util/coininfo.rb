#!/usr/bin/env ruby

require 'rubygems'
require 'ant'
require 'cryptocompare'
require 'json'
require 'fileutils'

antapi = Ant::API.new 'mkeen', 'cf374b781fe0413aa75ce8ebc2045401', '548d94a30bc24ae6a477b70e8c6bad6f'

poolacct =
  antapi.api_call 'account.htm', {coin: :DASH}, true

dashpric =
  Cryptocompare::Price.find :DASH, :USD

value = {
  usdval: poolacct['data']['earnTotal'].to_f * dashpric['DASH']['USD'],
  dashval: poolacct['data']['earnTotal'].to_f,
  dashprc: dashpric['DASH']['USD'],
  time: Time.now.to_i
}

directory = '/usr/share/antmine/'
FileUtils.mkdir_p directory
statsfile = directory + 'stats.json'

if FileTest.exist? statsfile
  json = IO.read statsfile
  ruby = JSON.parse json
  ruby << value
  IO.write statsfile, ruby.to_json
else
  ruby = [value]
  file = File.new statsfile, 'w'
  file.write ruby.to_json
  file.close
end
