class CreateLibrisItem

  def self.run(job:,
               logger: QueueManager.logger,
               libris_id:,
               sigel: nil,
               url: ,
               type: nil,
               place: nil,
               agency: nil,
               bibliographic_code: nil,
               create_holding: true,
               publicnote: nil,
               remark: nil,
               publicnote_holding: nil,
               remark_holding: nil)

    dcat_base_url = APP_CONFIG['dcat_base_url']
    dcat_api_key = APP_CONFIG['dcat_api_key']

    query = {
      "record": {
        "libris_id": libris_id,
        "sigel": sigel,
        "url": url,
        "type": type,
        "place": place,
        "agency": agency,
        "bibliographic_code": bibliographic_code,
        "create_holding": create_holding,
        "publicnote": publicnote,
        "remark": remark,
        "publicnote_holding": publicnote_holding,
        "remark_holding": remark_holding
      }
    }
    response = HTTParty.post("#{dcat_base_url}/?api_key=#{dcat_api_key}", :query => query)

    if !response
      raise StandardError, "Unknown error when trying to connect to dCat service}"
    elsif response.code != 201 && !response["error"]
      raise StandardError, "Error from dCat service, code: #{response.code}"
    elsif response.code != 201 && response["error"]
      raise StandardError, "Error from dCat service, code: #{response.code}, message: #{response['error']['msg']}"
    else
      publicationlog = PublicationLog.new(job: job, publication_type: 'DCAT_LIBRIS_ID', comment: response['electronic_item_id'])
      if !publicationlog.save
        raise StandardError, "Couldn't save publicationlog due to errors: #{publicationlog.errors}"
      end
      publicationlog = PublicationLog.new(job: job, publication_type: 'DCAT_HOLDING_ID', comment: response['holding_id'])
      if !publicationlog.save
        raise StandardError, "Couldn't save publicationlog due to errors: #{publicationlog.errors}"
      end
    end
    return true
  end

end
