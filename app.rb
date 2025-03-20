require 'sinatra'
require 'csv'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'fileutils'

CACHE_FILE = 'movie_cache.json'
IMAGE_DIR = 'public/film_images'
MOVIE_CACHE = File.exist?(CACHE_FILE) ? JSON.parse(File.read(CACHE_FILE), symbolize_names: true) : {}

# Ensure image directory exists
FileUtils.mkdir_p(IMAGE_DIR)

class Wishlist
  def initialize(file_path)
    @file_path = file_path
  end

  def pick_random_movies(count = 3)
    movies = CSV.read(@file_path, headers: true)
    movies.each.to_a.sample(count)
  end

  def fetch_thumbnail(imdb_id, title, year)
    key = "#{title.downcase.gsub(/\s+/, '_')}_#{year}"
    image_path = "#{IMAGE_DIR}/#{key}.jpg"

    # Use cached image if available
    return "/film_images/#{key}.jpg" if File.exist?(image_path)

    # Fetch image from IMDb
    url = "https://www.imdb.com/title/#{imdb_id}/"
    begin
      doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0'))
      image = doc.at_css('meta[property="og:image"]')
      if image
        File.write(image_path, URI.open(image['content']).read) # Save locally
        return "/film_images/#{key}.jpg"
      end
    rescue StandardError => e
      puts "Error fetching image: #{e.message}"
    end

    'No image found'
  end
end

file_path = 'waitlist.csv'
wishlist = Wishlist.new(file_path)

get '/' do
  @movies = wishlist.pick_random_movies.map do |movie|
    key = "#{movie['Title'].downcase.gsub(/\s+/, '_')}_#{movie['Year']}"
    
    # Return cached data if available
    if MOVIE_CACHE.key?(key)
      MOVIE_CACHE[key]
    else
      movie_data = {
        title: movie['Title'],
        year: movie['Year'],
        genre: movie['Genres'],
        rating: movie['IMDb Rating'],
        imdb_link: "https://www.imdb.com/title/#{movie['Const']}",
        thumbnail: wishlist.fetch_thumbnail(movie['Const'], movie['Title'], movie['Year'])
      }

      # Store in cache and persist to file
      MOVIE_CACHE[key] = movie_data
      File.write(CACHE_FILE, JSON.pretty_generate(MOVIE_CACHE))

      movie_data
    end
  end

  erb :index, layout: :layout
end
