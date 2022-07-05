# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'watir'
require 'webdrivers'
require 'uri'
require 'base64'
require './authorization.rb'
require './playlist_actions.rb'
require './playlist_class.rb'
require './track_class.rb'

# Defining all necessary variables
auth_url      = build_url
code          = get_code(auth_url)
access_token  = get_token(code)
user_id       = get_user_id(access_token)
playlist_id   = create_new_playlist(user_id, access_token)
snapshot_id   = add_tracks(playlist_id, access_token)

sleep 3
reorder_tracks(playlist_id, snapshot_id, access_token)
sleep 3
delete_tracks(playlist_id, snapshot_id, access_token)

# Populates the created Playlist with an array of it’s Tracks
tracks        = []
parsed_tracks = get_parsed_tracks(playlist_id, access_token)
number_tracks = parsed_tracks['total']

number_tracks.times do |i|
  id_track          = parsed_tracks['items'][i]['track']['id']
  name_track        = parsed_tracks['items'][i]['track']['name']
  artist_name       = parsed_tracks['items'][i]['track']['artists'][0]['name']
  album_name        = parsed_tracks['items'][i]['track']['album']['name']
  spotify_url_track = parsed_tracks['items'][i]['track']['href']

  tracks.push(Track.new(id_track, name_track, artist_name, album_name, spotify_url_track).json_format)
end

the_playlist = Playlist.new(playlist_id, access_token).json_format
the_playlist['tracks'] = tracks
puts the_playlist.to_json
