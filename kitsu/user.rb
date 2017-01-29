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
  def initialize(id, limit=2000, status='completed')
    @id = id
    @limit = limit
    @status = {
      'watching' => 1,
      'planned' => 2,
      'completed' => 3,
      'hold' => 4,
      'dropped' => 5
    }
    # https://kitsu.io/api/edge/library-entries?
    # filter[user_id]=52349&include=user,media&fields[user]=name&fields[media]=id,canonicalTitle
    @uri_query = [
      ["filter[user_id]", id],
      ['filter[media_type]', 'Anime'],
      ['filter[status]', @status[status]],
      # ['include', 'media'],
      ['include', 'user,media'],
      ['fields[user]', 'name'],
      ['fields[anime]', 'id,canonicalTitle'],
      ['page[limit]', @limit]]
    uri = Addressable::URI.parse("#{$api}/library-entries")
    uri.query_values = @uri_query
    @uri_library = uri.to_s
  end

  def details
    puts "user_id: #{@id}\nuri_library: #{@uri_library}"
  end

  def get_library
    response = $consumer.request(:get, @uri_library)
    return JSON.parse(response.body)
    # return get_data(@uri_library)
  end

  def get_library_item(id)
    return get_data("#{$api}/library-entries/#{id}")
  end

  def get_media_item(id, type='anime')
    return get_data("#{$api}/library-entries/#{id}/relationships/#{type}")
  end

  def name
    @name
  end

  def get_library_entries(verbose=false)
    if verbose
      puts "\nretreiving library items..."
    end
    lib = get_library()

    unless lib['data'].nil? | lib['included'].nil?
      anime_id_rating = {}
      lib['data'].each do |item|
        rating = item['attributes']['rating'].to_f
        id = item['relationships']['media']['data']['id'].to_i
        anime_id_rating[id] = rating
      end

      anime_id_title = {}
      lib['included'].each do |item|
        type = item['type']
        if type == 'users'
          @name = item['attributes']['name']
        elsif type == 'anime'
          id = item['id'].to_i
          title = item['attributes']['canonicalTitle']
          anime_id_title[id] = title
        end
      end

      records = []
      anime_id_title.each_pair do |id, title|
        record = {
          'anime_id' => id,
          'rating' => anime_id_rating[id],
          'title' => title
        }
        records << record
      end
    end

    # entries = []
    # n = lib['meta']['count'] - 1
    # (0..[n, @limit - 1].min).each do |i|
    #   if i == 0  # first item in list is user details as per @uri_query order
    #     @name = lib['included'][i]['attributes']['name']
    #   else
    #     anime_id = lib['included'][i]['id'].to_i
    #     anime_title = lib['included'][i]['attributes']['canonicalTitle']
    #     rating = lib['data'][i]['attributes']['rating']
    #     unless rating.nil?
    #       record = {
    #         :anime_id => anime_id,
    #         :rating => rating.to_f,
    #         :title => anime_title
    #       }
    #       entries << record
    #       if verbose
    #         puts "#{i} anime_id=#{anime_id}; rating=#{rating}; title=#{anime_title}"
    #       end
    #     end
    #   end
    # end
    if verbose
      puts "library retrieved."
    end
    # return entries
    return records
  end

end


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
  puts "\nquerying all documents in collection '#{collection}'."
  collection = client[collection]
  collection.find.each do |document|
    puts document
  end
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


def delete_all_records(collection_name)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection_name]
  collection.delete_many({})
  puts "all records deleted from '#{collection_name}' collection."
end


def get_user_libs(x, y)
  libs = []
  (x..y).each_with_index do |user_id, i|
    user = User.new(user_id)
    lib = user.get_library_entries
    # if lib.size > 0
    unless lib.nil?
      puts "#{i}: user_id=#{user_id}; lib_size=#{lib.size}"
      record = {:user_id => user_id, :name => user.name, :library => lib}
      libs << record
    end
  end
  return libs
end


# user = User.new(52345)  # 6 items all nil ratings
# user = User.new(52348)  # 160+ items
# user = User.new(52349)  # 2 items
# user = User.new(52350)  # 122 items
# # user = User.new(1)  # 222 items
# # user = User.new(2)  # 244 itBems
# user = User.new(8)  # 1700+ items
# user = User.new(4016)
# # user.details
# lib = user.get_library
# puts JSON.pretty_generate(lib)
# lib = user.get_library_entries(verbose=true)
# puts JSON.pretty_generate(lib)
# puts lib


# delete_all_records('users')
# libs = get_user_libs(11, 200)
libs = get_user_libs(4000, 4020)
update_db(libs, 'users')
# query_all('users')
#
# query = {'user_id' => {'$gt': 95}}
# query = {'library.rating' => {'$gte': 4}}
# query = {'library' => {'$elemMatch' => {'title' => 'Cowboy Bebop'}}}

def print_query(collection, query)
  client = Mongo::Client.new($client_host, $client_options)
  db = client.database
  collection = client[collection]
  cursor = collection.find(query)
  s = cursor.to_a
  puts JSON.pretty_generate(s)
end


class Collection
  def initialize(name)
    client = Mongo::Client.new($client_host, $client_options)
    @collection = client[name]
  end

  def pretty_print(cursor)
    puts JSON.pretty_generate(cursor.to_a)
  end

  def query(query)
    cursor = @collection.find(query)
    pretty_print(cursor)
  end
end


# collection = Collection.new('users')
# query = {'name' => 'muon'}
# collection.query(query)
