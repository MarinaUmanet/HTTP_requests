steps:
  - name: Variables
    env:
      CLIENT_ID: ${{ secrets.CLIENT_ID }}
      CLIENT_SECRET: ${{ secrets.CLIENT_SECRET }}
      EMAIL: ${{ secrets.EMAIL }}
      PASSWORD: ${{ secrets.PASSWORD }}
require 'rest-client'
require 'json'
require 'watir'
require 'webdrivers'
require 'uri'
require 'base64'


CLIENT_ID = "CLIENT_ID"
CLIENT_SECRET = "CLIENT_SECRET"
EMAIL = "EMAIL"
PASSWORD = "PASSWORD"
REDIRECT_URI = "http://localhost:8888/callback"
ADD_TRACKS_HERE = ["spotify:track:1vbn9fEyw1IYhqgZJdu9ZB","spotify:track:0e8nrvls4Qqv5Rfa2UhqmO","spotify:track:6kxaaIeowajN7w21PfMLbu"]

def build_url
  url = "https://accounts.spotify.com/authorize"
  url += "?client_id=" + CLIENT_ID
  url += "&response_type=code"
  url += "&redirect_uri=" + REDIRECT_URI
  url += "&scope=user-read-private playlist-read-private playlist-modify-private playlist-read-collaborative"
end


def get_code(auth_url)
  browser = Watir::Browser.new
  browser.goto(auth_url)
  login_field = browser.text_field(id: "login-username")
  login_field.set(EMAIL)
  pass_field = browser.text_field(id: "login-password")
  pass_field.set(PASSWORD)
  browser.button(:text => "Log In").click
  browser.button(:text => "Agree").click    //#Used for first acces only, disable when testing
  sleep 3
  uri = URI.parse(browser.url).to_s
  uri.split("code=").last
end


def get_token(code)
  encoded_client = Base64.encode64("#{CLIENT_ID}"":""#{CLIENT_SECRET}").delete("\n")
  token_url = "https://accounts.spotify.com/api/token"
  token_params = {
    "grant_type" => "authorization_code",
    "code" => code,
    "redirect_uri" => REDIRECT_URI

  }
  token_headers = {
    "Authorization" => "Basic #{encoded_client}",
    "Content-Type" => "application/x-www-form-urlencoded"
  }
  response = RestClient.post(token_url, token_params, token_headers)
  json_response = JSON.parse(response)
  json_response["access_token"]
end


def get_user_id(token)
  user_id_url = "https://api.spotify.com/v1/me"
  id_headers = {
    "Accept" => "application/json",
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{token}"
  }
  response_id = RestClient.get(user_id_url, id_headers)
  json_response_id = JSON.parse(response_id)
  json_response_id["id"]
end


def create_new_playlist(user_id, token)
  playlist_url = "https://api.spotify.com/v1/users/#{user_id}/playlists"
  playlist_params = {
    "name" => "My new playlist",
    "public" => false,
    "description" => "Awesome playlist",
    "collaborative" => true
  }
  playlist_headers = {
    "Authorization" => "Bearer #{token}",
    "Host" => "api.spotify.com"
  }
  playlist_response = RestClient.post(playlist_url, playlist_params.to_json, playlist_headers)
  json_playlist_response = JSON.parse(playlist_response)
  json_playlist_response["id"]
end


def add_tracks(playlist_id, token)
  tracks_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  tracks_params = {
    "uris" => ADD_TRACKS_HERE
  }
  tracks_headers = {
    "Authorization" => "Bearer #{token}",
    "Host" => "api.spotify.com"
  }
  tracks_response = RestClient.post(tracks_url, tracks_params.to_json, tracks_headers)
  json_tracks_response = JSON.parse(tracks_response)
  json_tracks_response["snapshot_id"]
end


def reorder_tracks(playlist_id, snapshot_id, token)
  tracks_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  reorder_params = {
    "range_start" => 0,
    "insert_before" => ADD_TRACKS_HERE.length,
    "snapshot_id" => snapshot_id
  }
  tracks_headers = {
    "Authorization" => "Bearer #{token}",
    "Host" => "api.spotify.com"
  }
  RestClient.put(tracks_url, reorder_params.to_json, tracks_headers)
end


def delete_tracks(playlist_id, snapshot_id, token)
  tracks_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  delete_params = {
    "tracks" => [{
                   "uri" => ADD_TRACKS_HERE[0],
                 }],
    "snapshot_id" => snapshot_id
  }
  tracks_headers = {
    "Authorization" => "Bearer #{token}",
    "Host" => "api.spotify.com"
  }
  RestClient::Request.execute(:method => :delete, :url => tracks_url, :payload => delete_params.to_json, :headers => tracks_headers)
end

class Playlist
  attr_accessor :id,
                :name,
                :description,
                :owner_name,
                :spotify_url,
                :tracks,
                :playlist_id,
                :token


  def initialize(playlist_id, token)
    self.playlist_id = playlist_id
    self.token = token
    self.id = parse_playlist["id"]
    self.name = parse_playlist["name"]
    self.description = parse_playlist["description"]
    self.owner_name = parse_playlist["owner"]["display_name"]
    self.spotify_url = parse_playlist["href"]
    self.tracks = []
  end

  def parse_playlist
    @get_playlist_url = "https://api.spotify.com/v1/playlists/#{self.playlist_id}"
    @playlist_headers = {
      "Authorization" => "Bearer #{self.token}",
      "Host" => "api.spotify.com"
    }
    playlist_response = RestClient.get(@get_playlist_url, headers = @playlist_headers)
    JSON.parse(playlist_response)
  end

  def json_format
    {
      "name" => self.name,
      "description" => self.description,
      "owner_name" => self.owner_name,
      "spotify_url" => self.spotify_url,
      "id" => self.id,
      "tracks" => self.tracks
    }
  end
end


class Track
  attr_accessor :id,
                :name,
                :artist_name,
                :album_name,
                :spotify_url

  def initialize(id, name, artist_name, album_name, spotify_url)
    self.id = id
    self.name = name
    self.artist_name = artist_name
    self.album_name = album_name
    self.spotify_url = spotify_url
  end

  def json_format
    {
      "name" => self.name,
      "artist_name" => self.artist_name,
      "album_name" => self.album_name,
      "spotify_url" => self.spotify_url,
      "id" => self.id
    }
  end
end

def get_parsed_tracks(playlist_id, token)
  @get_tracks_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  @playlist_headers = {
    "Authorization" => "Bearer #{token}",
    "Host" => "api.spotify.com"
  }
  get_tracks_response = RestClient.get(@get_tracks_url, headers = @playlist_headers)
  JSON.parse(get_tracks_response)
end

#Defining all necessary variables
auth_url = build_url
code = get_code(auth_url)
access_token = get_token(code)
user_id = get_user_id(access_token)
playlist_id = create_new_playlist(user_id, access_token)
snapshot_id = add_tracks(playlist_id, access_token)
sleep 3
reorder_tracks(playlist_id, snapshot_id, access_token)
sleep 3
delete_tracks(playlist_id, snapshot_id, access_token)

#Populates the created Playlist with an array of it’s Tracks
tracks = []
parsed_tracks = get_parsed_tracks(playlist_id, access_token)
number_tracks = parsed_tracks["total"]

(0..number_tracks - 1).each { |i|
  id_track = parsed_tracks["items"][i]["track"]["id"]
  name_track = parsed_tracks["items"][i]["track"]["name"]
  artist_name = parsed_tracks["items"][i]["track"]["artists"][0]["name"]
  album_name = parsed_tracks["items"][i]["track"]["album"]["name"]
  spotify_url_track = parsed_tracks["items"][i]["track"]["href"]
  tracks.push(Track.new(id_track, name_track, artist_name, album_name, spotify_url_track).json_format)
}

the_playlist = Playlist.new(playlist_id, access_token).json_format
the_playlist["tracks"] = tracks
puts the_playlist.to_json
