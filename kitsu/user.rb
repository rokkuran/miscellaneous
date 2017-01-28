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


class LibraryItem
  def initialize(id, title, rating, type)
    @id = id
    @title = title
    @rating = rating
    @type = type
  end
end


class User
  def initialize(id)
    @id = id
    # @url_user = "#{$api}/users/#{@id}"

    # @url_library = "#{@url_user}/relationships/library-entries"
    # @url_library = "#{@url_library}?filter[media_type]=Anime"

    @url_library = "#{$api}/library-entries?filter[user_id]=#{id}&filter[media_type]=Anime&include=media&fields[anime]=id"
    # @url_library = "#{$api}/library-entries?filter[user_id]=#{id}&filter[media_type]=Anime&fields[anime]=id"
    # @url_query = "#{$api}/library-entries?filter[user_id]=#{@id}"
    # @url_query = "#{@url_query}&filter[media_type]=Anime&include=media"
    # @url_query = "#{@url_query}&fields[anime]=id,canonicalTitle"
    # 52349&filter[media_type]=Anime&include=media&fields[anime]=id,canonicalTitle
  end

  def details()
    # puts "user_id: #{@id}\nurl_user: #{@url_user}\nurl_library: #{@url_library}"
    puts "user_id: #{@id}\nurl_library: #{@url_library}"
  end

  def get_library()
    return get_data(@url_library)
  end

  def get_library_item(id)
    return get_data("#{$api}/library-entries/#{id}")
  end

  def get_media_item(id, type='anime')
    return get_data("#{$api}/library-entries/#{id}/relationships/#{type}")
  end

  # def get_library_entries()
  #   puts "\nretreiving library items..."
  #   lib = get_library()
  #   entries = {}
  #   lib.each_with_index do |entry, i|
  #     # if i < 10
  #     library_id = entry['id']
  #     anime = get_media_item(library_id)
  #     item = get_library_item(library_id)
  #
  #     rating = item['attributes']['rating'].to_f
  #     unless rating.nil? | anime.nil?
  #       anime_id = anime['id'].to_i
  #       # entries << [library_id, rating, anime_id]
  #       entries[anime_id] = rating
  #       puts "#{i}: library_id=#{library_id}; rating=#{rating} | #{anime_id}"
  #       # end
  #     end
  #   end
  #   puts "library retrieved."
  #   return entries
  # end

  def get_library_entries()
    puts "\nretreiving library items..."
    lib = get_library()
    entries = {}
    # puts lib
    # data = lib['data']
    lib.each_with_index do |item, i|
      # puts item
      anime_id = item['relationships']['media']['data']['id'].to_i
      rating = item['attributes']['rating']
      # puts "#{anime_id} | #{rating}"
      # if i < 10
      # library_id = entry['id']
      # anime = get_media_item(library_id)
      # item = get_library_item(library_id)

      # rating = item['attributes']['rating'].to_f
      unless rating.nil?
        # anime_id = anime['id'].to_i
        # entries << [library_id, rating, anime_id]
        entries[anime_id] = rating.to_f
        puts "#{i}: #{anime_id} | rating=#{rating}"
        # end
      end
    end
    puts "library retrieved."
    return entries
  end

end


# user = User.new(52345)  # 6 items all nil ratings
# user = User.new(52348)  # 160+ items
user = User.new(52349)  # 2 items
# user = User.new(52350)  # 122 items
# user = User.new(1)  # 222 items
# user = User.new(2)  # 244 items
user.details
lib = user.get_library_entries
puts lib
