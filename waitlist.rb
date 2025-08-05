require 'sinatra'
require 'csv'
require 'nokogiri'
require 'open-uri'

class Wishlist
  def initialize(file_path)
    @file_path = file_path
  end

  def pick_random_movies(count = 3)
    movies = CSV.read(@file_path, headers: true)
    movies.each.to_a.sample(count)
  end

  def fetch_thumbnail(imdb_id)
    url = "https://www.imdb.com/title/#{imdb_id}/"
    doc = Nokogiri::HTML(URI.open(url, 'User-Agent' => 'Mozilla/5.0'))
    image = doc.at_css('meta[property="og:image"]')
    image ? image['content'] : 'No image found'
  rescue StandardError => e
    "Error fetching image: #{e.message}"
  end
end

file_path = 'waitlist.csv'
wishlist = Wishlist.new(file_path)

get '/' do
  @movies = wishlist.pick_random_movies.map do |movie|
    {
      title: movie['Title'],
      year: movie['Year'],
      genre: movie['Genres'],
      rating: movie['IMDb Rating'],
      imdb_link: "https://www.imdb.com/title/#{movie['Const']}",
      thumbnail: wishlist.fetch_thumbnail(movie['Const'])
    }
  end
  erb :index, layout: :layout
end
