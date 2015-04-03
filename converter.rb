require 'csv'
require 'optparse'

require 'bindata'

if ARGV.count != 4
  puts 'Usage: ruby converter.rb <direction[to_text|to_bin]> "<delimiter>" <input_file> <output_file>'
  exit 1
end
ARG_DIRECTION, ARG_DELIMITER, ARG_INPUT_FILE, ARG_OUTPUT_FILE = ARGV

if ARG_DIRECTION != 'to_text' && ARG_DIRECTION != 'to_bin'
  puts 'Possible directions: "to_text" and "to_bin"'
  exit 1
end
unless File.exist?(ARG_INPUT_FILE)
  puts "File #{ARG_INPUT_FILE} doesn't exist."
  exit 1
end
if File.exist?(ARG_OUTPUT_FILE)
  puts "File #{ARG_OUTPUT_FILE} already exists."
  exit 1
end

class EchRecordLe < BinData::Record
  endian :little
    int32 :callid
    int32 :acwtime
    int32 :onholdtime
    int32 :consulttime
    int32 :disptime
    int32 :duration
    int32 :segstart
    int32 :segstop
    int32 :talktime
    int32 :netintime
    int32 :origholdtime
    int16 :dispivector
    int16 :dispsplit
    int16 :firstivector
    int16 :split1
    int16 :split2
    int16 :split3
    int16 :trunkgroup
    int16 :tklocid
    int16 :origlocid
    int16 :answerlocid
    int16 :obslocid
    bit1 :assist
    bit1 :audiodifficulty
    bit1 :conference
    bit1 :daqueued
    bit1 :holdabn
    bit1 :malicious
    bit1 :observingcall
    bit1 :transferred
    bit1 :agentreleased
    int8 :acdnum
    int8 :calldisp
    int8 :disppriority
    int8 :holds
    int8 :segment
    int8 :ansreason
    int8 :origreason
    int8 :dispsklevel
    int8 :events0
    int8 :events1
    int8 :events2
    int8 :events3
    int8 :events4
    int8 :events5
    int8 :events6
    int8 :events7
    int8 :events8
    string :ucid, read_length: 21
    string :dispvdn, read_length: 8
    string :eqloc, read_length: 10
    string :firstvdn, read_length: 8
    string :origlogid, read_length: 10
    string :anslogid, read_length: 10
    string :lastobserver, read_length: 10
    string :dialednumber, read_length: 25
    string :callingparty, read_length: 13
    string :collectdigits, read_length: 17
    string :cwcdigits, read_length: 17
    string :callingII, read_length: 3
    string :cwcs0, read_length: 17
    string :cwcs1, read_length: 17
    string :cwcs2, read_length: 17
    string :cwcs3, read_length: 17
    string :cwcs4, read_length: 17
end

class Ech < BinData::Record
  endian :little
  int32 :fileversion
  int32 :filenumber
  array :records, read_until: :eof, type: :ech_record
end

class Converter
  def self.convert_from_binary_to_text
    input_file_io = File.open(ARG_INPUT_FILE)
    ech = Ech.read(input_file_io)

    CSV.open(ARG_OUTPUT_FILE, 'w', { col_sep: ARG_DELIMITER }) do |csv|
      csv << [ ech[:fileversion], ech[:filenumber] ]
      csv << ech.records.first.snapshot.to_h.keys
      ech.records.each do |record|
        csv << record.snapshot.to_h.values
      end
    end
  end

  def self.convert_from_text_to_binary
    ech = Ech.new
    columns = EchRecordLe.new.field_names

    csv_file_rows = CSV.read(ARG_INPUT_FILE, { col_sep: ARG_DELIMITER})
    csv_file_rows.each_with_index do |row, index|
      if index == 0
        ech[:fileversion], ech[:filenumber] = row.first.to_i, row.last.to_i
        next
      end

      if index == 1
        next
      end

      record = EchRecordLe.new
      columns.each_with_index do |column_name, index2|
        if EchRecordLe.new.send(column_name).class.to_s =~ /(Int)|(Bit)/
          record[column_name] = row[index2].to_i
        else
          record[column_name] = row[index2]
        end
      end

      ech[:records] << record
    end

    output_file_io = File.open(ARG_OUTPUT_FILE, 'wb')
    string = ech.to_binary_s
    output_file_io.write(string)
  end
end

if ARG_DIRECTION == 'to_text'
  Converter.convert_from_binary_to_text
  puts "Binary file #{ARG_INPUT_FILE} successfully converted to text #{ARG_OUTPUT_FILE}"
else
  Converter.convert_from_text_to_binary
  puts "Text file #{ARG_INPUT_FILE} successfully converted to binary #{ARG_OUTPUT_FILE}"
end
