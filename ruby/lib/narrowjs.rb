# Copyright (c) 2010 William R. Conant, WillConant.com
# Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php

require 'strscan'

module Narrowjs
	
	class Transformer
		
		def init
			@last_token = ''
		end
		
		def transform_line(line)
			scanner = StringScanner.new(line)
			
			parts = Array.new
			push_part = lambda do |type, source|
				if source =~ /(\S+)\s*$/
					@last_token = $1
				end
				
				parts << {
					type: type,
					source: source
				}				
			end
			
			while true
				if scanner.scan(/([^"'\/]*)(["'\/])/)
				
					push_part.call :code, scanner[1]
					quote = scanner[2]
					
					if quote == '/'
						if @last_token != '' and @last_token !~ /([=\(,;:\+\~]|return)$/
							push_part.call :code, quote
							next
						end
					end
					
					string_literal = ''
					string_literal << quote
					
					while true
						if scanner.scan(Regexp.new("([^#{quote}\\\\]*)([#{quote}\\\\])"))							
							string_literal << scanner[1]
							
							if scanner[2] == '\\'
								string_literal << scanner[2]
								string_literal << scanner.scan(/./)
							else
								string_literal << quote
								break
							end
						else
							string_literal << scanner.scan(/.*/)
							break
						end
					end
					
					push_part.call :string, string_literal
					
				else
					
					push_part.call :code, scanner.rest
					break
					
				end
			end
			
			result = ''
			parts.each do |part|
				if part[:type] == :code
					part[:source].gsub!(/\#\{/, 'function(){')
					part[:source].gsub!(/\#\(([^)]*)\)(\s*)\{/, 'function(\1)\2{')
					part[:source].gsub!(/\@([\w\$]+)/, 'this.\1')
					part[:source].gsub!(/\@/, 'this')
				end
				
				result << part[:source]
			end
			
			return result
		end # def transform_line
		
	end # class Transformer
	
end # module Narrowjs

