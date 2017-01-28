require 'oauth'
require 'json'
require 'mongo'
require 'addressable/uri'


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


class User
  def initialize(id)
    @id = id
    @uri_query = [
      ["filter[user_id]", id],
      ['filter[media_type]', 'Anime'],
      ['include', 'media'],
      ['fields[anime]', 'id'],
      ['page[limit]', 250]]
    uri = Addressable::URI.parse("#{$api}/library-entries")
    uri.query_values = @uri_query
    @uri_library = uri.to_s
  end

  def details
    puts "user_id: #{@id}\nuri_library: #{@uri_library}"
  end

  def get_library
    return get_data(@uri_library)
  end

  def get_library_item(id)
    return get_data("#{$api}/library-entries/#{id}")
  end

  def get_media_item(id, type='anime')
    return get_data("#{$api}/library-entries/#{id}/relationships/#{type}")
  end

  def get_library_entries(verbose=false)
    if verbose
      puts "\nretreiving library items..."
    end
    lib = get_library()
    entries = {}
    lib.each_with_index do |item, i|
      anime_id = item['relationships']['media']['data']['id'].to_i
      rating = item['attributes']['rating']
      unless rating.nil?
        entries[anime_id] = rating.to_f
        if verbose
          puts "#{i}: #{anime_id} | rating=#{rating}"
        end
      end
    end
    if verbose
      puts "library retrieved."
    end
    return entries
  end

end


# # user = User.new(52345)  # 6 items all nil ratings
# # user = User.new(52348)  # 160+ items
# # user = User.new(52349)  # 2 items
# user = User.new(52350)  # 122 items
# # user = User.new(1)  # 222 items
# # user = User.new(2)  # 244 items
# user.details
# lib = user.get_library_entries
# puts lib


def update_db(docs, collection)
  begin
    puts "\ninserting records in '#{collection}'..."
    client = Mongo::Client.new($client_host, $client_options)
    db = client.database
    collection = client[collection]
    result = collection.insert_many(docs)
    puts "records inserted: #{result.inserted_count}"
  rescue StandardError => err
    puts('error: ')
    puts(err)
  end
  puts "insertion complete.\n"
end


def query_all(collection)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection]
  collection.find.each do |document|
    puts document
  end
end


libs = []
(51..100).each_with_index do |user_id, i|
  user = User.new(user_id)
  lib = user.get_library_entries
  if lib.size > 0
    puts "#{i}: user_id=#{user_id}; lib_size=#{lib.size}"
    libs << {user_id => lib}
  end
end

update_db(libs, 'users')
# query_all('users')
