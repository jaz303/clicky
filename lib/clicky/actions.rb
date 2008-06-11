module Clicky::Actions
  
  ACTION_GROUPS = [
    { :name => 'Visitors',
      :actions => {
        'visitors-list'         => 'All visitors'
      }
    },
    { :name => 'Actions',
      :actions => {
        'actions-list'          => 'All actions'
      }
    },
    { :name => 'Searches',
      :actions => {
        'searches-recent'       => 'Searches that led someone to your site',
        'searches-unique'       => 'Searches that led someone to your site for the first time ever',
        'links-recent'          => 'Links that led someone to your site',
        'links-unique'          => 'Links that led someone to your site for the first time ever'
      }
    },
    { :name => 'Popular',
      :actions => {
        'searches'              => 'Full search queries',
        'searches-keywords'     => 'Search keywords',
        'searches-engines'      => 'Search engines',
        'links'                 => 'Incoming links (full URL)',
        'links-domains'         => 'Incoming links (by domain name)',
        'links-outbound'        => 'Outbound links',
        'pages'                 => 'Pages on your site',
        'pages-entrance'        => 'Entrance pages',
        'pages-exit'            => 'Exit pages',
        'downloads'             => 'File downloads (pictures, zip files etc)',
        'clicks'                => 'AJAX and Flash interactions',
        'countries'             => 'Visitors\' countries',
        'cities'                => 'Visitors\' cities',
        'languages'             => 'Languages',
        'web-browsers'          => 'Web browsers',
        'operating-systems'     => 'Operating systems',
        'screen-resolutions'    => 'Screen resolutions',
        'hostnames'             => 'Visitor hostnames',
        'organizations'         => 'Visitor organizations',
        'visitors-most-active'  => 'The people who have visited your site the most often',
        'traffic-sources'       => 'How visitors are arriving at your site',
        'feedburner-clicks'     => 'Feedburner clicks',
        'feedburner-views'      => 'Feedburner views'
      }
    },
    { :name => 'Tallies',
      :actions => {
        'site-rank'               => 'Current ranking amongst all other sites registered on Clicky',
        'visitors'                => 'Number of visitors',
        'visitors-unique'         => 'Number of unique visitors',
        'actions'                 => 'Number of visitor actions',
        'actions-average'         => 'Average number of actions per visitor',
        'time-average'            => 'Average time on site per visitor',
        'time-total'              => 'Total time spent on your site',
        'bounce-rate'             => '% of visitors who only viewed one page',
        'visitors-online'         => 'Number of visitors currently active on your web site'
        'feedburner-subscribers'  => 'Number of Feedburner subscribers'
      }
    }
  ].freeze
  
end