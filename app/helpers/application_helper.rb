module ApplicationHelper
    def embed_youtube_video(video_id)
        content_tag(:iframe, nil, src: "https://www.youtube.com/embed/#{video_id}", width: 560, height: 315, frameborder: 0, allowfullscreen: true)
    end
end
