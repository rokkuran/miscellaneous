require 'oauth'
require 'json'
require 'mongo'


# kitsu.io api authentication details
$api = "https://kitsu.io/api/edge/"
$consumer = OAuth::Consumer.new(
  "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd",
  "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151")

# mongodb config
Mongo::Logger.logger.level = Logger::WARN
$client_host = ['127.0.0.1:27017']
$client_options = {database: 'kitsu'}


def get_base_request(url)
  return $consumer.request(:get, url)
end


def get_data(url)
  response = $consumer.request(:get, url)
  return JSON.parse(response.body)['data']
end


def get_doc(type, id)
  return get_data("#{$api}#{type}/#{id}")
end


def get_genres(type, id)
  doc = get_data("#{$api}#{type}/#{id}/relationships/genres")
  genres = []
  doc.each do |x|
    if x['type'] == 'genres'
      genres << x['id'].to_i
    end
  end
  return genres
end


def field_key_replace(doc, fields, s, r)
  fields.each do |field|
    encoded = {}
    doc[field].each_pair do |k, v|
      encoded[k.tr(s, r)] = v.to_i
    end
    doc[field] = encoded
  end
  return doc
end


def encode(doc, fields)
  return field_key_replace(doc, fields, '.', '-')
end


def decode(doc, fields)
  return field_key_replace(doc, fields, '-', '.')
end


def transform_media(doc)
  x = {:id => doc['id'].to_i}
  x = x.merge(doc['attributes'])

  q = {}
  x['ratingFrequencies'].each_pair do |k, v|
    q[k.tr('.', '-')] = v.to_i
  end
  x['ratingFrequencies'] = q

  return x
end


def get_media(type='anime', from=1, to=6)
  docs = []
  for id in from..to
    doc = get_doc(type, id)
    unless doc.nil?
      doc = transform_media(doc)
      doc['genres'] = get_genres(type, id)
      docs << doc
      puts "#{id}: #{doc['slug']}"
    end
  end
  return docs
end


def update_db(docs, collection)
  begin
    puts "inserting records in '#{collection}'..."
    client = Mongo::Client.new($client_host, $client_options)
    db = client.database
    collection = client[collection]
    result = collection.insert_many(docs)
    puts "records inserted: #{result.inserted_count}"
  rescue StandardError => err
    puts('error: ')
    puts(err)
  end
  puts "insertion complete."
end


def query_db(collection)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection]
  collection.find.each do |document|
    print document
  end
end


def delete_all_records(collection_name)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection_name]
  collection.delete_many({})
  puts "all records deleted from '#{collection_name}' collection."
end


def test_data_requests()
  a = get_data('https://kitsu.io/api/edge/anime/1')
  b = get_doc('anime', 1)
  return a == b
end


def query_db_params(collection, query)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection]

  cursor = collection.find(query)
  puts 'query results:'
  cursor.each_with_index do |row, idx|
    puts "#{idx}: #{row}"
  end
end

# query = {'id' => {'$gt': 49}}
# query = {'id' => 1}
# query = {'slug' => 'cowboy-bebop'}
query = {'averageRating' => {'$gt' => 4.2}}
# query = {
#   'averageRating' => {'$gt' => 4.2},
#   'genres' => {'$in' => [4]},
#   'genres' => {'$in' => [20]}
# }
query_db_params('anime', query)

# puts get_doc('anime', 165)
# puts get_genres('anime', 1)
# docs = get_media('anime', 1, 50)
# docs = get_media('anime', 51, 52)
# docs = get_media('anime', 53, 150)
# docs = get_media('anime', 151, 151)
# docs = get_media('anime', 152, 250)
# docs = get_media('anime', 501, 1000)
# docs = get_media('anime', 251, 500)
# update_db(docs, 'anime')
# query_db('anime')
# delete_all_records('anime')
#
