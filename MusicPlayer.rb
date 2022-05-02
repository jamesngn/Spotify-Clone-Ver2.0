#This library is to create a music player bar
#The function includes:
#Play/Pause the song
#Skip next, previous songs
#Shuffle songs
#Repeat mode: 1,2,3
#Volume bar
#Display playing track
require 'gosu'
require 'rubygems'
require_relative 'GUI Music Player Pass Task'
SCREEN_WIDTH = 900
SCREEN_HEIGHT = 600

TOP_COLOR = Gosu::Color.new(0xFFEBF5FB) 
PLAYER_COLOUR = Gosu::Color.new(0xFF282828)
BACKGROUND_COLOUR = Gosu::Color.new(0xFF181818)
SIDE_COLOUR = Gosu::Color.new(0xFF121212)
module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

class TextField < Gosu::TextInput
  # Some constants that define our appearance.
  INACTIVE_COLOR  = 0xcc666666
  ACTIVE_COLOR    = 0xccff6666
  SELECTION_COLOR = 0xcc0000ff
  CARET_COLOR     = 0xffffffff
  PADDING = 5
  
  attr_accessor :x, :y,:entered_text

  def initialize(window, font, x, y, text)
    # TextInput's constructor doesn't expect any arguments.
    super()
    @enter_icon = Gosu::Image.new("images/enter.png")
    @window, @font, @x, @y, @text  = window, font, x, y, text
    
    # Start with a self-explanatory text in each field.
    self.text = @text
    @constant_width = @font.text_width(self.text)
  end
  
  # Example filter method. You can truncate the text to employ a length limit (watch out
  # with Ruby 1.8 and UTF-8!), limit the text to certain characters etc.
  def filter text
    text.upcase
  end
  
  def draw
    # Depending on whether this is the currently selected input or not, change the
    # background's color.
    if @window.text_input == self then
      background_color = ACTIVE_COLOR
    else
      background_color = INACTIVE_COLOR
    end
    @window.draw_quad(x - PADDING,         y - PADDING,          background_color,
                      x + @constant_width + PADDING, y - PADDING,          background_color,
                      x - PADDING,         y + height + PADDING, background_color,
                      x + @constant_width + PADDING, y + height + PADDING, background_color, 0)
    
    # Calculate the position of the caret and the selection start.
    pos_x = x + @font.text_width(self.text[0...self.caret_pos])
    sel_x = x + @font.text_width(self.text[0...self.selection_start])
    
    # Draw the selection background, if any; if not, sel_x and pos_x will be
    # the same value, making this quad empty.
    @window.draw_quad(sel_x, y,          SELECTION_COLOR,
                      pos_x, y,          SELECTION_COLOR,
                      sel_x, y + height, SELECTION_COLOR,
                      pos_x, y + height, SELECTION_COLOR, 0)

    # Draw the caret; again, only if this is the currently selected field.
    if @window.text_input == self then
      @window.draw_line(pos_x, y,          CARET_COLOR,
                        pos_x, y + height, CARET_COLOR, 0)
    end

    # Finally, draw the text itself!
    @font.draw(self.text, x, y, 0)

    @enter_icon.draw_rot(@x - 25, @y + @font.height/2, ZOrder::PLAYER,0)
  end

  # This text field grows with the text that's being entered.
  # (Usually one would use clip_to and scroll around on the text field.)
  def width
    @font.text_width(self.text)
  end
  
  def height
    @font.height
  end

  # Hit-test for selecting a text field with the mouse.
  def under_point?(mouse_x, mouse_y)
    mouse_x > x - PADDING and mouse_x < x + @constant_width + PADDING and
      mouse_y > y - PADDING and mouse_y < y + height + PADDING
  end

  def click_enter?(mouse_x,mouse_y)
    mouse_x > @x - 25 - 13 and mouse_y > @y + @font.height/2 - 35/2 and
    mouse_x < @x - 25 + 13 and mouse_y < @y + @font.height/2 + 35/2
  end

  # Tries to move the caret to the position specifies by mouse_x
  def move_caret(mouse_x)
    # Test character by character
    1.upto(self.text.length) do |i|
      if mouse_x < x + @font.text_width(text[0...i]) then
        self.caret_pos = self.selection_start = i - 1;
        return
      end
    end
    # Default case: user must have clicked the right edge
    self.caret_pos = self.selection_start = self.text.length
  end
end

class SearchPage
    attr_accessor :search,:results
    def initialize(album)
        @albums = album
        @results = Array.new()
    end

    def search
        @search 
    end

    def check_result(song_name,search,search_length)
        if search_length - 1 <= song_name.size && search_length > 0
            return false if song_name.size == search_length - 1 
            return true if song_name[0..(search_length - 1)] == search
            check_result(song_name[1..song_name.size],search,search_length)
        end
    end

    def check_results(search,song_array)
        if search.size > 0
            for i in 0..(song_array.size - 1)
                if check_result(song_array[i].name.upcase,search,search.size)
                    @results << song_array[i] if !@results.include?(song_array[i])
                else
                    @results.delete song_array[i]
                end
            end
        elsif search.size == 0
            @results = []
        end
        return @results
    end

    def display_search_results(search_result,xpos,ypos_i) 
        for i in 0..(search_result.size - 1)
            search_result[i].display_track(xpos,ypos_i)
            ypos_i += 30
        end
    end
end

class MusicPlayerBar

    class VolumeBar
        attr_accessor :x_coord, :y_coord, :x_size, :y_size, :volume_value,:playing_song
        def initialize(x_coord,y_coord,x_size,y_size,volume_value,playing_song)
            super()
            @x_coord, @y_coord,@x_size, @y_size, @volume_value, @playing_song = x_coord, y_coord, x_size, y_size, volume_value, playing_song
            @volume_icons_tiles = Gosu::Image.load_tiles('images/volume_icons_tiles_small.png',35,32)
        end

        def adjust_volume_value(mouse_x,hold)
            if hold
                if mouse_x < x_coord
                    @volume_value = 0
                elsif mouse_x > x_coord + x_size
                    @volume_value = x_size
                else
                    @volume_value = (mouse_x - x_coord).to_i
                end
            end
        end
        
        def draw
            Gosu.draw_rect(@x_coord,@y_coord,@x_size,@y_size,Gosu::Color::BLACK,ZOrder::PLAYER,mode=:default)
            Gosu.draw_rect(@x_coord,@y_coord,@volume_value,@y_size,Gosu::Color::WHITE,ZOrder::PLAYER,mode=:default)
            volume_value = @volume_value.to_f/x_size
            if volume_value == 1
                @volume_icons_tiles[0].draw_rot(@x_coord - 27,@y_coord + 5,ZOrder::PLAYER,0)
            elsif volume_value >= 0.25 && volume_value <1
                @volume_icons_tiles[1].draw_rot(@x_coord - 27,@y_coord + 5,ZOrder::PLAYER,0)
            elsif volume_value > 0 && volume_value <0.25
                @volume_icons_tiles[2].draw_rot(@x_coord - 27,@y_coord + 5,ZOrder::PLAYER,0)
            elsif volume_value == 0
                @volume_icons_tiles[3].draw_rot(@x_coord - 27,@y_coord + 5,ZOrder::PLAYER,0)
            end      
        end    
    end

    
    attr_accessor :thickness,:song,:font,:playing_song,:volume_bar
    def initialize(window,thickness,font,playing_song)
        super()
        @window,@thickness,@font,@playing_song = window, thickness, font, playing_song
        @volume_bar = VolumeBar.new(700,SCREEN_HEIGHT - @thickness/2 - 8,150,15,100,playing_song)   
        @right_arrow_img = Gosu::Image.new("images/right-arrow.png")
        @play_button_img = Gosu::Image.new("images/play.png")
        @pause_button_img = Gosu::Image.new("images/pause.png")
        @next_button_img = Gosu::Image.new('images/next.png')
		@previous_button_img = Gosu::Image.new('images/previous.png')
        @volume_icons_tiles = Gosu::Image.load_tiles('images/volume_icons_tiles_small.png',21,19)
        repeat_one_img = Gosu::Image.new('images/repeat_one.png')
        repeat_all_img = Gosu::Image.new('images/repeat_all.png')
        not_repeat_img = Gosu::Image.new('images/not_repeat.png')
        @repeat_img_tiles = [not_repeat_img,repeat_all_img,repeat_one_img]
    end

    def display_playing_song(name)
        @font.draw_text(name,75,SCREEN_HEIGHT - @thickness/2 - 10,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
    end

    def draw_repeat_buttons(repeat_mode)
        @repeat_img_tiles[repeat_mode].draw_rot(SCREEN_WIDTH/2 + 100, SCREEN_HEIGHT - @thickness/2,ZOrder::PLAYER,0)
    end

    def draw
        Gosu.draw_rect(0,SCREEN_HEIGHT - @thickness,SCREEN_WIDTH,@thickness,PLAYER_COLOUR) #background of music player bar
        @next_button_img.draw_rot(SCREEN_WIDTH/2 + 50, SCREEN_HEIGHT - @thickness/2, ZOrder::PLAYER,0)
        @previous_button_img.draw_rot(SCREEN_WIDTH/2 - 50, SCREEN_HEIGHT - @thickness/2, ZOrder::PLAYER,0)
        @volume_bar.draw
    end
end


class Playing_Song
    attr_accessor :albums,:album_ID,:track_ID,:name,:file,:paused
    def initialize(albums,album_ID,track_ID)
        @albums, @album_ID, @track_ID = albums, album_ID, track_ID
        @tracks_count = @albums[@album_ID].tracks.size
        
    end

    def name
        @name = @albums[album_ID].tracks[track_ID].name.chomp
    end

    def skip(increment)
        @track_ID = (@track_ID + increment)% @tracks_count
        play
    end

    def pause
        @file.pause 
        @paused = true
    end

    def continue
        @file.play 
        @paused = false
    end

    def paused
        @paused 
    end

    def repeat_mode(repeat_mode)
        if @file
            case repeat_mode
            when 1
                if !@file.playing? && !@paused
                    @track_ID = (@track_ID + 1)% @tracks_count
                    play
                end
            when 2
                play if !@file.playing? && !@paused
            end
        end
    end

    def play
        location = @albums[@album_ID].tracks[@track_ID].location
        @file = Gosu::Song.new(location.chomp)
        @file.play(false)
        @paused = false
    end
end

class ListButtonPosition
    def initialize(volume_bar)
        @volume_bar = volume_bar
    end
    def skip_previous?(mouse_x, mouse_y)
        mouse_x > 387 and mouse_y > 563 and
        mouse_x < 412 and mouse_y < 587
    end

    def skip_next?(mouse_x, mouse_y)
        mouse_x > 487 and mouse_y > 563 and
        mouse_x < 513 and mouse_y < 587
    end

    def repeat_mode?(mouse_x, mouse_y)
        mouse_x > 532 and mouse_y > 557 and
        mouse_x < 565 and mouse_y < 589
    end

    def play_pause?(mouse_x, mouse_y)
        mouse_x > 430 and mouse_y > 555 and
        mouse_x < 466 and mouse_y < 592
    end

    def volume_icon?(mouse_x, mouse_y)
        mouse_x > 661 and mouse_y > 568 and
        mouse_x < 681 and mouse_y < 586
    end

    def volume_bar?(mouse_x,mouse_y)
        mouse_x > @volume_bar.x_coord &&
        mouse_x < @volume_bar.x_coord + @volume_bar.x_size &&
        mouse_y > @volume_bar.y_coord &&
        mouse_y < @volume_bar.y_coord + @volume_bar.y_size
    end

    def switch_album_page?(mouse_x,mouse_y)
        mouse_x > 75 and mouse_x < 485 and
        mouse_y > 70 and mouse_y  < 550
    end

    def switch_song_page?(mouse_x,mouse_y)
        mouse_x > 550 and mouse_y > 50 and
        mouse_x < 900 and mouse_y < 500
    end

    def favourite_buttons?(mouse_x,mouse_y)
        mouse_x > 520 and mouse_y > 48 and
        mouse_x < 542 and mouse_y < 490
    end

    def home_page?(mouse_x,mouse_y)
        mouse_x > 10 and mouse_y > 10 and
        mouse_x < 60 and mouse_y < 60
    end

    def favourite_page?(mouse_x,mouse_y)
        mouse_x > 10 and mouse_y > 70 and 
        mouse_x < 60 and mouse_y < 118
    end  
    
    def search_page?(mouse_x,mouse_y)
        mouse_x > 10 and mouse_y > 130 and 
        mouse_x < 60 and mouse_y < 180       
    end

    def add_playlist?(mouse_x,mouse_y)
        mouse_x > 10 and mouse_y > 190 and 
        mouse_x < 60 and mouse_y < 240
    end

    def close?(mouse_x,mouse_y)
        mouse_x > 855 and mouse_y > -25 and
        mouse_x < 900 and mouse_y < 0
    end

    def click_done?(mouse_x,mouse_y)
        mouse_x > 526 and mouse_y > 17 and
        mouse_x < 597 and mouse_y < 44
    end
end

class UI_Album

    class ArtWork
        attr_accessor :bmp
        def initialize (file)
            @bmp = Gosu::Image.new(file)
        end
    end
        
    attr_accessor :albums,:album_ID,:leftX, :topY, :rightX, :bottomY, :UI_Song
    def initialize(albums,album_ID)
        @album_ID = album_ID
        @albums = albums
        self.UI_Song = Array.new(@albums[album_ID].tracks.size) {|x| UI_Song.new(@albums, album_ID,x)}
        @large_artwork = ArtWork.new(@albums[@album_ID].artwork.chomp)
        @small_artwork = ArtWork.new(@albums[@album_ID].small_artwork.chomp)
        @font23 = Gosu::Font.new(23)
        @font15 = Gosu::Font.new(15)
        @leftX = 120
        @topY = 75 + 200 * (@album_ID%2)
        @rightX = 280
        @bottomY = @topY + 160
    end

    def display_album(ypos)
        @large_artwork.bmp.draw(120,ypos,ZOrder::PLAYER)
        @font23.draw_text(@albums[@album_ID].title,290,ypos + 5, ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
        @font15.draw_text("By " + @albums[@album_ID].artist,290, ypos + 30,ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
        @font15.draw_text($genre_names[@albums[@album_ID].genre.to_i],290,ypos + 50,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
        @font15.draw_text(@albums[@album_ID].tracks.length().to_s + " tracks",290,ypos + 70,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
    end

    def display_tracks(xpos,ypos,track_page)
        for track_ID in 0..(@albums[@album_ID].tracks.size-1)
            if self.UI_Song[track_ID].track_page == track_page
                self.UI_Song[track_ID].display_track(xpos,ypos) 
                ypos += 30 
            end
        end
    end

    def clicked?(mouse_x,mouse_y)
        mouse_x > @leftX and mouse_y > @topY and
        mouse_x < @rightX and mouse_y < @bottomY
    end
end

class UI_Song
    attr_accessor :albums,:album_ID,:track_ID,:track_page,:favourite,:name,:location, :draw_circle, :playlist, :list_page
    def initialize(albums,album_ID,track_ID)
        @albums,@album_ID,@track_ID = albums, album_ID, track_ID
        @track_page = @track_ID / 15
        @font20 = Gosu::Font.new(20)
        @heart1_img = Gosu::Image.new('images/heart_not_added_small.png')
        @heart2_img = Gosu::Image.new('images/heart_added_small.png')
        @added_img = Gosu::Image.new('images/added.png')
        @not_added_img = Gosu::Image.new('images/not_added.png')
        @name = @albums[@album_ID].tracks[@track_ID].name.chomp
        @location = @albums[@album_ID].tracks[@track_ID].location.chomp
        @added = false
        @list_page = 0
        @playlist = []
    end

    def favourite
        @favourite
    end

    def display_track(xpos, ypos)
        @font20.draw_text(@albums[@album_ID].tracks[@track_ID].name,xpos,ypos,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
        @leftX, @topY  = xpos, ypos
        @rightX = @leftX + @font20.text_width(@albums[@album_ID].tracks[@track_ID].name)
        @bottomY = @topY + 20
        if @album_ID <= 3
            if !@favourite 
                @heart1_img.draw_rot(xpos-20,ypos+10,ZOrder::PLAYER,0) 
            else
                @heart2_img.draw_rot(xpos-20,ypos+10,ZOrder::PLAYER,0)
            end
            @leftXF, @topYF, @rightXF = @leftX - 30, ypos, @leftX - 10
            @bottomYF = @topYF + 17
        end
    end

    def draw_circle(xpos,ypos,playlist_index)
        if !self.playlist[playlist_index]
            @not_added_img.draw_rot(xpos+325,ypos+@font20.height/2,ZOrder::PLAYER,0)
        else
            @added_img.draw_rot(xpos+325,ypos+@font20.height/2,ZOrder::PLAYER,0)
        end
        @leftXA, @topYA,  @bottomYA = xpos + 315, ypos, ypos + 20
        @rightXA = @leftXA + 20
    end

    def click_song?(mouse_x,mouse_y)
        mouse_x > @leftX and mouse_y > @topY and
        mouse_x < @rightX and mouse_y < @bottomY 
    end

    def click_favourite?(mouse_x,mouse_y)
        mouse_x > @leftXF and mouse_y > @topYF and 
        mouse_x < @rightXF and mouse_y < @bottomYF 
    end

    def click_add?(mouse_x,mouse_y,list_page)
        mouse_x > @leftXA and mouse_y > @topYA and
        mouse_x < @rightXA and mouse_y < @bottomYA and
        @list_page == list_page
    end
end

def convert_current_favourite_file_into_text_by_name(array_of_favourite_list)
    text_location = "myfavourite.txt"
    text_file = File.new(text_location,"w")
    text_file.puts array_of_favourite_list.size()
    for line in 0..(array_of_favourite_list.size() -1)
        text_file.puts array_of_favourite_list[line].name.chomp
    end
    text_file.close()
end

def convert_text_document_into_array(list_all_songs) 
    text_location = "myfavourite.txt"
    text_file = File.open(text_location)
    counts = text_file.gets().to_i
    favourite_list = Array.new()
    for line in 0..(counts - 1)
        name = text_file.gets().chomp
        favourite_list << check_song_name_with_list_all_songs(name, list_all_songs) 
    end
    return favourite_list
end

def check_song_name_with_list_all_songs(song_name,list_all_songs)
    for i in 0..(list_all_songs.size() - 1)
        if song_name == list_all_songs[i].name
            list_all_songs[i].favourite = true
            return list_all_songs[i]
            break
        end
    end
    return
end

class NewPlaylist < ListButtonPosition
    attr_accessor :added_songs,:done, :index, :name,:rename_tf
    def initialize(name,index)
        @name = name
        @index = index
        @font25 = Gosu::Font.new(25)
        @done = false
        @added_songs = Array.new()
        @delete_img = Gosu::Image.new("images/delete.png")
    end

    def added_songs
        @added_songs
    end

    def display_all_songs_to_add(list_all_songs,track_page,index)
        if !self.done
            ypos = 50
            xpos = 550
            list_all_songs.each do |song|     
                song.draw_circle = true
                if song.list_page == track_page
                    song.display_track(xpos,ypos)
                    song.draw_circle(xpos,ypos,index)
                    ypos += 30 
                end
            end
            @font25.draw_text("DONE", 530, 20,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
            Gosu.draw_rect(525,17,72,27,Gosu::Color::RED,ZOrder::BACKGROUND,mode=:default)
        end
    end

    def display_playlist_button(xpos,ypos)
        if self.done
            @font25.draw_text(self.name, xpos, ypos + 40 * (@index - 1),ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
            title = self.name
            width = @font25.text_width(title)
            Gosu.draw_rect(xpos ,ypos - 3 + 40 * (@index - 1),width,27,Gosu::Color::BLUE,ZOrder::BACKGROUND,mode=:default)
            @delete_img.draw_rot(xpos -25,ypos + 10 + 40 * (@index - 1),ZOrder::PLAYER,0)
            @leftXB,@topYB,@rightXB,@bottomYB = xpos,ypos + 40 * (@index - 1),xpos + width, ypos + 27 + 40 * (@index - 1)
            @leftXD,@topYD,@rightXD,@bottomYD = xpos - 38, ypos - 5 + 40 * (@index - 1), xpos - 12, ypos + 25 + 40 * (@index - 1)
        end        
    end

    def create_txt_files
        if !self.done
            wfile = File.new("new_playlists/mydata" + @index.to_s + ".txt","w") 
            wfile.puts "Quang Nguyen"
            wfile.puts self.name
            wfile.puts "images/artwork/new_playlist.jpg"
            wfile.puts "images/artwork/new_playlist_small.jpg"
            wfile.puts 2
            wfile.puts @added_songs.size
            @added_songs.each do |element| 
                wfile.puts element.name
                wfile.puts element.location
            end
            wfile.close()
        end
    end

    def saved_songs_added_from_the_last_time(list_all_songs)
        wfile = File.open("new_playlists/mydata" + @index.to_s + ".txt","r")
        wfile.gets()
        wfile.gets()
        wfile.gets()
        wfile.gets()
        wfile.gets()
        songs_count = wfile.gets().to_i
        for i in 0..(songs_count - 1)
            name = wfile.gets().to_s.chomp
            location = wfile.gets().to_s.chomp
            list_all_songs.each do |song|
                if name == song.name
                    song.playlist[@index] = true 
                    @added_songs.push song
                    break
                end
            end
        end
    end

    def click_playlist_to_edit?(mouse_x,mouse_y)
        mouse_x > @leftXB and mouse_y > @topYB and
        mouse_x < @rightXB and mouse_y < @bottomYB
    end

    def click_delete?(mouse_x,mouse_y)
        mouse_x > @leftXD and mouse_y > @topYD and
        mouse_x < @rightXD and mouse_y < @bottomYD
    end

    def control(mouse_x, mouse_y)
        self.done = true; return nil if self.click_done?(mouse_x,mouse_y)
        self.done = false; return @index if self.click_playlist_to_edit?(mouse_x,mouse_y)
    end

end

def read_added_new_playlists_from_txt_file
    wfile = File.open("new_playlists/playlist_counts.txt")
    playlist_counts = wfile.gets().to_i
    new_playlist = []
    for i in 0..(playlist_counts - 1)
        name = wfile.gets().to_s.chomp
        new_playlist.push NewPlaylist.new(name,i+1)
        new_playlist[i].done = true
    end
    return playlist_counts, new_playlist
end

class MusicPlayerWindow < Gosu::Window

    def initialize
        super(SCREEN_WIDTH,SCREEN_HEIGHT,false) 
        @font23 = Gosu::Font.new(23)
        @font40 = Gosu::Font.new(40)
        @font16 = Gosu::Font.new(16)
        @play_button_img = Gosu::Image.new("images/play.png")
        @pause_button_img = Gosu::Image.new("images/pause.png")
        @home_page_img = Gosu::Image.new("images/HomePage.png")
        @favourite_page_img = Gosu::Image.new("images/favourite_page.png")
        @search_page_img = Gosu::Image.new("images/Search-PNG-High-Quality-Image.png")
        @add_playlist_img = Gosu::Image.new("images/addplaylist.png")
        music_file = File.new("albums.txt","r")
        @albums = read_albums(music_file)
        @UI_album = Array.new(@albums.size) {|x| UI_Album.new(@albums,x)}
        @music_player_bar = MusicPlayerBar.new(self,thickness = 50,font = @font23, @playing_song)  
        @volume_bar = @music_player_bar.volume_bar
        @mouse = ListButtonPosition.new(@volume_bar)
        @repeat_mode = 0 
        @current_album_page = 0
        @chosen_album_ID = nil
        @page = 0
        @track_page = 0

        @text_fields = Array.new(1) {TextField.new(self,@font23,620,10,"Search by Song")}
        @search_page = SearchPage.new(@albums)
        @list_all_songs = Array.new()
        original_file = File.new("original_albums.txt","r")
        original_album = read_albums(original_file)
        #@UI_album = Array.new(original_album.size) {|x| UI_Album.new(original_album,x)}
        index = -1
        for album_ID in 0..(original_album.size - 1)
            for track_ID in 0..(original_album[album_ID].tracks.size - 1)
                index += 1
                @UI_album[album_ID].UI_Song[track_ID].list_page = index / 15
                @list_all_songs.push @UI_album[album_ID].UI_Song[track_ID]
            end
        end
        @favourite_list = convert_text_document_into_array(@list_all_songs)

        playlist_counts,@new_playlist = read_added_new_playlists_from_txt_file()
        for i in 0..(playlist_counts - 1)
            @new_playlist[i].saved_songs_added_from_the_last_time(@list_all_songs)
        end
        @current_new_playlist_index = nil
    end

    def area_clicked
        if @page == 0
            if @mouse.switch_album_page?(mouse_x,mouse_y)
                for i in 0..1
                    if  @UI_album[i + @current_album_page * 2] && @UI_album[i + @current_album_page * 2].clicked?(mouse_x,mouse_y)
                        @chosen_album_ID = i + @current_album_page * 2
                        @track_page = 0
                    end
                end
            elsif @mouse.switch_song_page?(mouse_x,mouse_y) && @chosen_album_ID
                for i in 0..(@albums[@chosen_album_ID].tracks.size - 1)
                    if (@UI_album[@chosen_album_ID].UI_Song[i].track_page == @track_page && 
                            @UI_album[@chosen_album_ID].UI_Song[i].click_song?(mouse_x,mouse_y))
                        @playing_TRACK_ID = i
                        @playing_ALBUM_ID = @chosen_album_ID
                        @playing_song = Playing_Song.new(@albums,@playing_ALBUM_ID,@playing_TRACK_ID)
                        @playing_song.play
                    end
                end
            elsif @mouse.favourite_buttons?(mouse_x,mouse_y) && @chosen_album_ID && @chosen_album_ID <= 3
                for i in 0..(@albums[@chosen_album_ID].tracks.size - 1)
                    if @UI_album[@chosen_album_ID].UI_Song[i].track_page == @track_page and
                        @UI_album[@chosen_album_ID].UI_Song[i].click_favourite?(mouse_x,mouse_y) 
                        song = @UI_album[@chosen_album_ID].UI_Song[i]
                        if !@favourite_list.include?(song)
                            song.favourite = true
                            @favourite_list.push song
                        else   
                            song.favourite = false
                            @favourite_list.delete song
                        end
                    end
                end
            end
        elsif @page == 1
            for i in 0..(@favourite_list.size - 1)
                if @favourite_list[i].click_song?(mouse_x,mouse_y)
                    @playing_ALBUM_ID = @favourite_list[i].album_ID
                    @playing_TRACK_ID = @favourite_list[i].track_ID
                    @playing_song = Playing_Song.new(@albums,@playing_ALBUM_ID,@playing_TRACK_ID)
                    @playing_song.play
                elsif @favourite_list[i].click_favourite?(mouse_x,mouse_y)
                    @favourite_list[i].favourite = false
                    @favourite_list.delete @favourite_list[i]  
                    break
                end
            end
        elsif @page == 2
            for i in 0..(@search_page.results.size - 1)
                if @search_page.results[i].click_song?(mouse_x,mouse_y)
                    @playing_ALBUM_ID = @search_page.results[i].album_ID
                    @playing_TRACK_ID = @search_page.results[i].track_ID
                    @playing_song = Playing_Song.new(@albums,@playing_ALBUM_ID,@playing_TRACK_ID)
                    @playing_song.play
                    break
                end
                if @search_page.results[i].click_favourite?(mouse_x,mouse_y)
                    if !@favourite_list.include?(@search_page.results[i])
                        @search_page.results[i].favourite = true 
                        @favourite_list.push @search_page.results[i]
                    else
                        @search_page.results[i].favourite = false 
                        @favourite_list.delete @search_page.results[i]
                    end
                end
            end
        elsif @page == 3
            if !@new_playlist.empty?
                if @current_new_playlist_index == nil
                    @new_playlist.each do |playlist| 
                        if playlist.done && playlist.click_playlist_to_edit?(mouse_x,mouse_y)
                            @current_new_playlist_index = playlist.index
                            playlist.done = false
                            break
                        end
                        if playlist.done && playlist.click_delete?(mouse_x,mouse_y)
                            index = playlist.index
                            for i in index..(@new_playlist.size-1)
                                @new_playlist[i].index -= 1
                            end
                            @new_playlist.delete playlist    
                            
                            @list_all_songs.each do |song|
                                song.playlist[index] = false 
                            end
                            if @playing_song
                                @playing_song = nil if @playing_song.album_ID == 3 + index
                            end
                            update_albums_txt_file_when_creating_a_new_playlist()                   
                        end
                    end
                else
                    if @mouse.click_done?(mouse_x,mouse_y)
                        @new_playlist[@current_new_playlist_index - 1].done = true
                        @current_new_playlist_index = nil
                        @text_fields[1] = TextField.new(self,@font23,125,25,"New Playlist Name")
                    end
                    if !@new_playlist[@current_new_playlist_index.to_i - 1].done
                        @list_all_songs.each do |song|
                            if song.list_page == @track_page
                                if song.click_add?(mouse_x,mouse_y,@track_page)
                                    list = @new_playlist[@current_new_playlist_index - 1].added_songs
                                    if !list.include?(song)
                                        list.push song
                                        song.playlist[@current_new_playlist_index] = true
                                    else
                                        list.delete song
                                        song.playlist[@current_new_playlist_index] = false 
                                    end                              
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    def display_albums()
        @font40.draw_text("ALBUM LIST",160,10,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
        @font16.draw_text("Page #{@current_album_page+1}",230,46,ZOrder::PLAYER,1.0,1.0,Gosu::Color::WHITE)
        ypos = 75
        for index in 0..1
            @UI_album[index + @current_album_page * 2].display_album(75 + 200 * (index % 2)) if @UI_album[index + @current_album_page * 2]
        end
    end

    def display_favourite_tracks()
        ypos = 50
        xpos = 120
        for index in 0..(@favourite_list.size - 1)
            ypos = 50 + 30*(index%15)
            xpos = 120 + (index / 15)*240
            @favourite_list[index].display_track(xpos,ypos)
        end
    end

    def draw_play_pause_buttons
        if @playing_song
            if @playing_song.file.playing?
                @play_button_img.draw_rot(SCREEN_WIDTH/2, SCREEN_HEIGHT - 50/2, ZOrder::PLAYER,0)
            else
                @pause_button_img.draw_rot(SCREEN_WIDTH/2, SCREEN_HEIGHT - 50/2, ZOrder::PLAYER,0)
            end
        else
            @pause_button_img.draw_rot(SCREEN_WIDTH/2, SCREEN_HEIGHT - 50/2, ZOrder::PLAYER,0)
        end
    end

    def draw
		Gosu.draw_rect(0,0,960,600,BACKGROUND_COLOUR,ZOrder::BACKGROUND,mode=:default)	
        Gosu.draw_rect(0,0,75,600,SIDE_COLOUR,ZOrder::BACKGROUND,mode=:default)        
        Gosu.draw_rect(485,0,475,600,Gosu::Color.new(0xFF363636),ZOrder::BACKGROUND,mode=:default) 

        @home_page_img.draw_rot(35,35,ZOrder::PLAYER,0)
        @favourite_page_img.draw_rot(35,95,ZOrder::PLAYER,0)
        @search_page_img.draw_rot(35,155,ZOrder::PLAYER,0)
        @add_playlist_img.draw_rot(35,215,ZOrder::PLAYER,0)

        @music_player_bar.draw
        @music_player_bar.display_playing_song(@playing_song.name)  if @playing_song
        @music_player_bar.draw_repeat_buttons(@repeat_mode)
        draw_play_pause_buttons      

        if @page == 0
            display_albums()
            @UI_album[@chosen_album_ID].display_tracks(550,50,@track_page) if @chosen_album_ID 
        elsif @page == 1
            display_favourite_tracks() 
        elsif @page == 2
            @text_fields[0].draw
            @search_page.results = @search_page.check_results(@search,@list_all_songs)
            @search_page.display_search_results(@search_page.results,130,30)
        elsif @page == 3
            @text_fields[1].draw if @text_fields[1]
            if !@new_playlist.empty?
                @new_playlist[@current_new_playlist_index.to_i-1].display_all_songs_to_add(@list_all_songs,@track_page,@current_new_playlist_index)
                if @current_new_playlist_index == nil
                    @new_playlist.each do |playlist|
                        playlist.display_playlist_button(150,100)
                    end
                end
            end
        end
    end

    def needs_cursor?;true;end

    def saved_playlists_added_from_the_last_time()
        wfile = File.new("new_playlists/playlist_counts.txt","w")
        wfile.puts(@new_playlist.size)
        for i in 0..(@new_playlist.size() - 1)
            wfile.puts @new_playlist[i].name
        end
        wfile.close()
    end
    
    def update_albums_txt_file_when_creating_a_new_playlist
        wfile = File.new("albums.txt","w")
        wfile.puts 4 + @new_playlist.size
        File.foreach("original_albums.txt").with_index do |line, line_no|
            wfile.puts line if line_no > 0
        end
        
        for i in 1..(@new_playlist.size)
            File.readlines("new_playlists/mydata"+i.to_s+".txt").each do |line|
                wfile.puts line
            end
        end
        wfile.close()
        wfile = File.open("albums.txt")
        
        @albums = read_albums(wfile)
        for i in 4..(@albums.size() - 1)
            @UI_album[i] = UI_Album.new(@albums,i)
        end
        wfile.close()
    end

    def update
        (@hold = true if button_down?(Gosu::MsLeft))if @mouse.volume_bar?(mouse_x,mouse_y)
        (@hold = false) if !button_down?(Gosu::MsLeft)
        @volume_bar.adjust_volume_value(mouse_x,@hold)
        @playing_song.file.volume = @volume_bar.volume_value.to_f/@volume_bar.x_size if @playing_song
        @playing_song.repeat_mode(@repeat_mode) if @playing_song
        @search = @search_page.search = @text_fields[0].text  
        convert_current_favourite_file_into_text_by_name(@favourite_list)

        @list_all_songs.each {|song| song.draw_circle = false} if @page != 3

        if @current_new_playlist_index != nil
            @text_fields[1] = nil 
            @new_playlist[@current_new_playlist_index-1].create_txt_files  
        end
        saved_playlists_added_from_the_last_time()  
    end

    def button_down(id)
        if @playing_song
            case id 
            when Gosu::MsLeft
                @playing_song.skip(1) if @mouse.skip_next?(mouse_x,mouse_y)
                @playing_song.skip(-1) if @mouse.skip_previous?(mouse_x,mouse_y)
                if @mouse.volume_icon?(mouse_x,mouse_y)
                    if @volume_bar.volume_value > 0
                        @previous_volume_value = @volume_bar.volume_value
                        @volume_bar.volume_value = 0 
                    elsif @volume_bar.volume_value == 0
                        @volume_bar.volume_value = @previous_volume_value
                    end
                end
                if @mouse.repeat_mode?(mouse_x,mouse_y)
                    @repeat_mode = (@repeat_mode + 1) % 3
                end
                if @mouse.play_pause?(mouse_x,mouse_y)
                    if @playing_song.file
                        if @playing_song.file.playing?
                            @playing_song.pause
                        else
                            @playing_song.continue
                        end
                    end
                end
            when Gosu::KbSpace
                if @playing_song.file
                    if @playing_song.file.playing?
                        @playing_song.pause
                    else
                        @playing_song.continue 
                    end 
                end
            when Gosu::KbRight
                @playing_song.skip(1)
            when Gosu::KbLeft
                @playing_song.skip(-1)
            end
        end
        case id
        when Gosu::MsLeft
            area_clicked
            if @mouse.home_page?(mouse_x,mouse_y)
                @page = 0; @current_album_page = 0; @chosen_album_ID = nil
                update_albums_txt_file_when_creating_a_new_playlist()
                sleep(0.1)
            end
            @page = 1 if @mouse.favourite_page?(mouse_x,mouse_y)
            @page = 2 if @mouse.search_page?(mouse_x,mouse_y)
            if @mouse.add_playlist?(mouse_x,mouse_y) 
                @text_fields[1] = TextField.new(self,@font23,125,25,"New Playlist Name") 
                @page = 3
            end
            if @text_fields[1] && @text_fields[1].click_enter?(mouse_x,mouse_y) 
                @new_playlist.push NewPlaylist.new(@text_fields[1].text, @new_playlist.size() + 1)
                @current_new_playlist_index = @new_playlist.size()
            end
            self.text_input = @text_fields.find { |tf| tf.under_point?(mouse_x, mouse_y) if tf} 
            self.text_input.move_caret(mouse_x) unless self.text_input.nil?
        when 260 # mouse roll down the albums
            if @page == 0
                if @mouse.switch_album_page?(mouse_x,mouse_y) && @current_album_page < (@albums.size)/2 - (1 - @albums.size % 2)
                    @current_album_page += 1
                end
                if @mouse.switch_song_page?(mouse_x,mouse_y) && @track_page < (@albums[@chosen_album_ID].tracks.size-1)/15
                    @track_page += 1
                end 
            elsif @page == 3
                if @mouse.switch_song_page?(mouse_x,mouse_y) && @track_page < (@list_all_songs.size() -1)  / 15
                    @track_page += 1
                end
            end
        when 259 # mouse roll up the albums
            if @page == 0
                if @mouse.switch_album_page?(mouse_x,mouse_y) && @current_album_page > 0
                    @current_album_page -=1
                end
                if @mouse.switch_song_page?(mouse_x,mouse_y) && @track_page > 0
                    @track_page -= 1
                end
            elsif @page == 3
                if @mouse.switch_song_page?(mouse_x,mouse_y) && @track_page > 0
                    @track_page -= 1
                end
            end
        when Gosu::KbEscape 
            close()
        end
    end  
end
MusicPlayerWindow.new.show()