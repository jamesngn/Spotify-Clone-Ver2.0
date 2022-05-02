require_relative 'input_functions'
require 'gosu'
require 'rubygems'
# It is suggested that you put together code from your 
# previous tasks to start this. eg:
# TT3.2 Simple Menu Task
# TT5.1 Music Records
# TT5.2 Track File Handling
# TT6.1 Album file handling

# Task 6.1 T - use the code from last week's tasks to complete this:
# eg: 5.1T, 5.2T

module Genre
  POP, CLASSIC, JAZZ, ROCK = *1..4
end
$genre_names = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']
class Album
  attr_accessor :artist, :title, :genre, :tracks, :artwork,:small_artwork
  def initialize(artist,title,genre,tracks,artwork,small_artwork)
    @artist = artist
    @title = title
    @genre = genre
    @tracks = tracks
    @artwork = artwork
    @small_artwork = small_artwork
  end
end
class Track
  attr_accessor :name, :location
  def initialize(name,location)
    @name = name
    @location = location
  end
end
def read_track(music_file)
  name = music_file.gets()
  location = music_file.gets()
  track = Track.new(name,location)
end
def read_tracks(music_file,track_count)
  i = 0
  tracks = Array.new()
  while i < track_count
    track = read_track(music_file)
    tracks << track
    i+=1
  end
  return tracks
end
def read_album(music_file)
  artist = music_file.gets()
  title = music_file.gets()
  artwork = music_file.gets()
  small_artwork = music_file.gets()
  genre = music_file.gets()
  track_count = music_file.gets().to_i()
  #if track_count <= 15
    tracks = read_tracks(music_file,track_count)
    album = Album.new(artist,title,genre,tracks,artwork,small_artwork)
    return album
  #else
    #puts "Reselect the music file with less than 15 tracks."
  #end
end

def read_albums(music_file)
  album_count = music_file.gets().to_i
  i = 0
  albums = Array.new()
  while i < album_count
    album = read_album(music_file)
    albums << album
    i+=1
  end
  return albums
end

def read_in_albums()
  begin 
    file_location = read_string("Enter the text file location: ") 
    music_file = File.new(file_location,"r") 
  rescue Errno::ENOENT => e
  end

  if music_file.nil?
    puts ("File does not exist. Please enter again")
    file_inserted = -1
    albums = nil
    return albums,file_inserted 
  else
    album_count = music_file.gets().to_i
    i = 0
    albums = Array.new()
    while i < album_count
      album = read_album(music_file)
      albums << album
      i += 1
    end
    file_inserted = 1
    return albums,file_inserted
  end
end

def print_album(album,id)
  puts "ALBUM ID " + id.to_s
  puts "-= " + $genre_names[album.genre.to_i].to_s + "=-"
  puts "> #{album.title.to_s} by #{ album.artist.to_s}" 
  puts
end
def display_albums(albums)
  option = read_integer_in_range("1: Display all\n2: Display by genres",1,2)
  if option == 1
    i = 0
    while i < albums.length()
      print_album(albums[i],i+1)
      i+=1
    end
  elsif option == 2
    puts "Select a genre to display:"
    option = read_integer_in_range("1. Pop\n2. Classic\n3. Jazz\n4. Rock",1,4)
    i = 0 
    while i < albums.length
      if albums[i].genre.to_i == option
        print_album(albums[i],i+1)
      end
      i += 1
      if i == albums.length
        puts "No " + $genre_names[option].to_s + " genre in the album"
      end
    end
  end
end

def update_title(albums,album_id)
  puts "Current title: #{albums[album_id-1].title}"
  updated_title = read_string("New title: ")
  albums[album_id-1].title = updated_title
  return updated_title
end

def update_genre(albums,album_id)
  puts ("1. Pop\n2. Classic\n3. Jazz\n4. Rock")
  puts "Current genre: #{$genre_names[albums[album_id-1].genre.to_i].to_s}"
  updated_genre = read_integer_in_range("New genre: ",1,4)
  return updated_genre
end

def update_album(albums)
  albums_count = albums.length
  album_id = read_integer_in_range("Update ALBUM ID: ",1,albums_count)
  option = read_string("1.Change title\n2.Change genre\nPress Enter to return main menu")
  album = albums[album_id-1]
  if option == "1"
    album.title = update_title(albums, album_id)
  elsif option == "2"
    album.genre = update_genre(albums, album_id)
  elsif option.empty?
    finished = true
  else
    puts "Invalid input"
  end
  print_album(album,album_id)
  return albums
end

def print_track(track)
  puts track.name
end
def print_tracks(tracks)
  i = 0
  while i < tracks.length
    print (i+1).to_s + "."
    print_track(tracks[i])
    i += 1
  end
end

def play_by_id(albums)
  albums_count = albums.length
  album_id = read_integer_in_range("Album ID: ",1, albums_count)
  album = albums[album_id - 1]
  tracks_count = album.tracks.length
  if tracks_count > 0
    print_tracks(album.tracks)
    track_id = read_integer_in_range("Play track: ",1,tracks_count)
    return album_id,track_id
  else
    puts "No track in the ALBUM ID " + album_id.to_s
  end
end

def song(albums,album_id,track_id)
  if album_id != nil && track_id != nil
    track_name = albums[album_id-1].tracks[track_id-1].name
    track_location = albums[album_id-1].tracks[track_id-1].location
    puts ("NOW PLAYING: ")
    print (track_name.to_s)
    print ("By artist " + albums[album_id-1].artist)
    print ("From album " + albums[album_id-1].title)
    return track_location
  end
end

def play_by_track_name(albums,search_track_name)
  albums_count = albums.length()
  album_id = 0
  while album_id < albums_count
    album = albums[album_id]
    tracks_count = album.tracks.length
    track_id = 0
    while track_id < tracks_count
      if album.tracks[track_id].name.chomp == search_track_name
        return album_id+1,track_id+1
        break
      else
        track_id += 1
      end
    end
    album_id += 1
    if album_id == albums_count then
      puts "Unable to find the track name " + search_track_name.to_s
      return nil,nil
    end
  end
end

def play_album(albums)
  puts("Play Album")
  option = read_string("1 - Play by ID\n2 - Search by track name\nPress Enter to return main menu")
  if option == "1"
    album_id,track_id = play_by_id(albums)
    song(albums,album_id,track_id)
  elsif option == "2"
    search_track_name = read_string("Track name: ")
    album_id,track_id = play_by_track_name(albums,search_track_name)
    song(albums,album_id,track_id)
  elsif option.empty?
  else
    puts "Invalid Option"
  end
end





def read_favourite_file(favourite_file)
    favourite_track_list = Array.new()
    favourite_location_list = Array.new()
    i = 0
    favourite_file.gets()
    favourite_file.gets()
    favourite_file.gets()
    favourite_file.gets()
    favourite_file.gets()
    tracks_count = favourite_file.gets().to_i
    for i in 0..(tracks_count-1)
        favourite_track_list[i] = favourite_file.gets().chomp
        favourite_location_list[i] = favourite_file.gets().chomp
    end
    return favourite_track_list,favourite_location_list
end 

def main1
  finished = false
  file_inserted = -1
  while finished == false
    puts "MAIN MENU:\n1: Read in Albums\n2: Display Albums\n3: Select an Album to play\n4: Update an existing Album\n5: Exit"
    option = read_integer_in_range("Please select an option",1,5)
    if option == 1 
      albums, file_inserted = read_in_albums()
    elsif option == 5 
      finished = true
    end
    if (option > 1 && option < 5) && file_inserted == -1 then
      puts("Music file does not exist")    
      finished = true
    else 
      case option
      when 2
        display_albums(albums)
      when 3
        play_album(albums)
      when 4
        albums = update_album(albums)
      end   
    end   
  end
  return albums 
end




