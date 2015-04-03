require 'csv'
require 'optparse'
require 'bindata'

if ARGV.count != 5
  puts 'Usage: ruby converter.rb <direction[to_text]> "<delimiter>" <input_file> <output_file> <output_metafile>'
  puts 'Usage: ruby converter.rb <direction[to_bin]> "<delimiter>" <input_file> <input_metafile> <output_file>'
  exit 1
end
ARG_DIRECTION, ARG_DELIMITER = ARGV[0], ARGV[1]

if ARG_DIRECTION != 'to_text' && ARG_DIRECTION != 'to_bin'
  puts 'Possible directions: "to_text" and "to_bin"'
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
  string :ucid,           length: 21,  trim_padding: true
  string :dispvdn,        length: 8,   trim_padding: true
  string :eqloc,          length: 10,  trim_padding: true
  string :firstvdn,       length: 8,   trim_padding: true
  string :origlogid,      length: 10,  trim_padding: true
  string :anslogid,       length: 10,  trim_padding: true
  string :lastobserver,   length: 10,  trim_padding: true
  string :dialednumber,   length: 25,  trim_padding: true
  string :callingparty,   length: 13,  trim_padding: true
  string :collectdigits,  length: 17,  trim_padding: true
  string :cwcdigits,      length: 17,  trim_padding: true
  string :callingII,      length: 3,   trim_padding: true
  string :cwcs0,          length: 17,  trim_padding: true
  string :cwcs1,          length: 17,  trim_padding: true
  string :cwcs2,          length: 17,  trim_padding: true
  string :cwcs3,          length: 17,  trim_padding: true
  string :cwcs4,          length: 17,  trim_padding: true
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

    CSV.open(ARG_OUTPUT_METAFILE, 'w', { col_sep: ARG_DELIMITER }) do |csv|
      csv << [:fileversion, ech.fileversion]
      csv << [:filenumber,  ech.filenumber]
    end

    CSV.open(ARG_OUTPUT_FILE, 'w', { col_sep: ARG_DELIMITER }) do |csv|
      csv << ech.records.first.snapshot.to_h.keys
      ech.records.each do |record|
        csv << record.snapshot.to_h.values
      end
    end
  end

  def self.convert_from_text_to_binary
    ech = Ech.new

    csv_metafile_rows = CSV.read(ARG_INPUT_METAFILE, { col_sep: ARG_DELIMITER })
    csv_metafile_rows.each_with_index do |row, index|
      ech[row.first] == row.last.to_i
    end

    columns = EchRecordLe.new.field_names

    csv_file_rows = CSV.read(ARG_INPUT_FILE, { col_sep: ARG_DELIMITER })
    csv_file_rows.each_with_index do |row, index|
      if index == 0
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
  ARG_INPUT_FILE, ARG_OUTPUT_FILE, ARG_OUTPUT_METAFILE = ARGV[2], ARGV[3], ARGV[4]

  unless File.exist?(ARG_INPUT_FILE); puts "File #{ARG_INPUT_FILE} doesn't exist."; exit 1; end
  if File.exist?(ARG_OUTPUT_FILE); puts "File #{ARG_OUTPUT_FILE} already exists."; exit 1; end
  if File.exist?(ARG_OUTPUT_METAFILE); puts "File #{ARG_OUTPUT_METAFILE} already exists."; exit 1; end

  Converter.convert_from_binary_to_text

  puts "Binary file #{ARG_INPUT_FILE} successfully converted to text #{ARG_OUTPUT_FILE}"
else
  ARG_INPUT_FILE, ARG_INPUT_METAFILE, ARG_OUTPUT_FILE  = ARGV[2], ARGV[3], ARGV[4]

  unless File.exist?(ARG_INPUT_FILE); puts "File #{ARG_INPUT_FILE} doesn't exist."; exit 1; end
  unless File.exist?(ARG_INPUT_METAFILE); puts "File #{ARG_INPUT_METAFILE} doesn't exist."; exit 1; end
  if File.exist?(ARG_OUTPUT_FILE); puts "File #{ARG_OUTPUT_FILE} already exists."; exit 1; end

  Converter.convert_from_text_to_binary

  puts "Text file #{ARG_INPUT_FILE} successfully converted to binary #{ARG_OUTPUT_FILE}"
end
