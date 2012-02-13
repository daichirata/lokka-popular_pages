require 'garb'

module Lokka
  module PopularPages
    def self.registered(app)
      app.get '/admin/plugins/popular_pages' do
        haml :"plugin/lokka-popular_pages/views/index", :layout => :"admin/layout"
      end

      app.put '/admin/plugins/popular_pages' do
        params.each_pair do |k, v|
          Option.send("#{k}=", v)
        end

        flash[:notice] = 'Updated.'
        redirect '/admin/plugins/popular_pages'
      end

      app.helpers do
        def popular_pages(option = {})
          return unless Analytics.valid?

          Analytics.response(option).map do |res|
            Entry(res.page_path.sub(/\//, ""))
          end.compact
        end
      end
    end

    module Analytics
      class Upvs
        extend Garb::Model

        metrics :pageviews
        dimensions :page_title, :page_path
      end

      class << self
        attr_accessor :profile, :time_stamp

        def response(option)
          default =
            { :limit      => 10,
              :sort       => :pageviews.descending,
              :start_date => (1.month.ago Time.now).beginning_of_month,
              :end_date   => (1.month.ago Time.now).end_of_month }

          update_span = option.delete(:update_span) || 12
          profile(update_span).upvs(default.merge(option))
        end

        def profile(span)
          if update?(span)
            if @profile
              Thread.new { @profile = _profile }
            else
              @time_stamp = Time.now
              @profile = _profile
            end
          end
          @profile
        end

        def _profile
          Garb::Session.login(Option.popular_pages_email, Option.popular_pages_password)
          Garb::Management::Profile.all.detect {|p| p.web_property_id == Option.popular_pages_tracker}
        end

        def update?(span)
          return true unless @time_stamp

          if @time_stamp + (60 * 60 * span.to_i) < Time.now
            @time_stamp = Time.now
          end
        end

        def valid?
          %w(popular_pages_tracker popular_pages_password popular_pages_email).all? do |attr|
            Option.send(attr).present?
          end
        end

      end
    end
  end
end


