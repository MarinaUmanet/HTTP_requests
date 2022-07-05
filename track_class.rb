# frozen_string_literal: true

class Track
  attr_accessor :id,
                :name,
                :artist_name,
                :album_name,
                :spotify_url

  def initialize(id, name, artist_name, album_name, spotify_url)
    self.id          = id
    self.name        = name
    self.artist_name = artist_name
    self.album_name  = album_name
    self.spotify_url = spotify_url
  end

  def json_format
    {
      'name': name,
      'artist_name': artist_name,
      'album_name': album_name,
      'spotify_url': spotify_url,
      'id': id
    }
  end
end

def get_parsed_tracks(playlist_id, token)
  @get_tracks_url   = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  @playlist_headers = {
    'Authorization': "Bearer #{token}",
    'Host': 'api.spotify.com'
  }

  get_tracks_response = RestClient.get(@get_tracks_url, headers = @playlist_headers)
  JSON.parse(get_tracks_response)
end
