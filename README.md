# Lokka Popular Pages

using google analytics api, to get the most accessed entry for the specified period

## Installation

    $ cd APP_ROOT/public/plugins/
    $ git clone git@github.com:daic-h/lokka-popular_pages.git

## How to Use

 option / default

    :limit / 10
    :sort / :pageviews.descending
    :start_date / (1.month.ago Time.now).beginning_of_month
    :end_date / (1.month.ago Time.now).end_of_month

 e.g.

    <% popular_pages.each do |entry| #retrun Entry instance %>
      <%= link_to entry.title, entry.link %>
    <% end %>

 If you would like to change end date

    <% popular_pages(:end_date => Time.now).each do |entry| #retrun Entry instance %>
      <%= link_to entry.title, entry.link %>
    <% end %>

