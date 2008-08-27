class Version
  include DataMapper::Resource
  
  property :id,		        Integer, :serial => true
  # Disabled lazy-loading as it was causing the first call to these attributes to return nil
  property :content,      Text,    :lazy => false, :nullable => false
  property :content_html, Text,    :lazy => false
  property :created_at,   DateTime
  property :moderated,    Boolean, :default => false
  property :remote_ip,    String
  property :spam,         Boolean, :default => false
  property :spaminess,    Float,   :default => 0
  property :signature,    String
  
  belongs_to :page
  
  before(:valid?) { populate_content_html unless content.blank? }

  def self.most_recent_unmoderated(max=100)
    all(:moderated => false, :limit => max, :order => [:created_at.desc])
  end
  
  def self.create_spam(page_name, options={})
    create(
      options.update(
        :spam    => true, 
        :page_id => -1, 
        :content => [options[:content], page_name].join(':')
      )
    )
  end
  
  def self.recent(number = 10)
    all(:limit => number, :order => [:id.desc], :spam => false)
  end

  def additions
    diff.gsub("\t", '').scan(/^\+(.*)/).flatten.join("\n")
  end

  def diff
    previous_content = previous.try(:content_html) || ''
    Diff.cs_diff(previous_content, content_html, :unified, 0)
  end

  def previous(versions)
    index = versions.index(self)
    index == 0 ? nil : versions[index-1]
  end
  
  def spam_or_ham
    spam? ? 'spam' : 'ham'
  end
  
private

  def linkify_bracketed_phrases(string)
    string.gsub(/\[\[([^\]]+)\]\]/) { "<a href=\"/pages/#{Page.slug_for($1.strip)}\">#{$1.strip}</a>" }
  end

  def populate_content_html
    content_with_internal_links = linkify_bracketed_phrases(content)
    self.content_html = RedCloth.new(content_with_internal_links).to_html
  end
  
end
