require 'google/apis/youtube_v3'

class YoutubeService
  def initialize
    @service = Google::Apis::YoutubeV3::YouTubeService.new
    @service.key = ENV[AIzaSyC8gc1af5JyiFyQV-iQR9PLIPMO1nfalAg]
  end

  def get_video(video_id)
    @service.list_videos('snippet', id: video_id).items.first
  end
end
