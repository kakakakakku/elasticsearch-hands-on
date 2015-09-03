require 'csv'
require 'json'

ES_INDEX_NAME = 'gourmet'
ES_TYPE_NAME = 'restaurants'

row_csv = CSV.read('restaurants.csv')
header = row_csv.slice!(0)
data = row_csv

OUTPUT_FILENAME = 'bulk_restaurants.json'

File.delete(OUTPUT_FILENAME) if File.exist?(OUTPUT_FILENAME)
File.open(OUTPUT_FILENAME, 'a') do |file|
  data.each do |row|
    index = { index: { _index: ES_INDEX_NAME, _type: ES_TYPE_NAME, _id: row[0] } }
    file.puts(JSON.dump(index))
    hash = Hash[header.zip(row)]
    file.puts(JSON.dump(hash))
  end
end
