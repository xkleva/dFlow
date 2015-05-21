module Requests
  module StubRequests
    def global_stubs
      stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\?api_key=test_key&source_file=PACKAGING:\/.+\/pdf\/.+\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "PACKAGING PDF", :headers => {})

      # This must come after the generic one, to override this specific case
      stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\?api_key=test_key&source_file=PACKAGING:\/9999\/pdf\/9999\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})



      stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\.json\?api_key=test_key&source_file=PACKAGING:\/.+\/pdf\/.+\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      # This must come after the generic one, to override this specific case
      stub_request(:get, /http:\/\/dfile\.example\.org\/download_file\.json\?api_key=test_key&source_file=PACKAGING:\/9999\/pdf\/9999\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})


      stub_request(:get, /http:\/\/dfile\.example\.org\/download_file.json\?api_key=test_key&source_file=STORE:\/.+\/pdf\/.+\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "STORE PDF", :headers => {})

      stub_request(:get, "http://dfile.example.org/download_file?api_key=test_key&source_file=PACKAGING://pdf/.pdf").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})

      stub_request(:get, "http://dfile.example.org/download_file.json?api_key=test_key&source_file=PACKAGING://pdf/.pdf").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})

      stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&show_catalogues=true&source_dir=STORE:GUB0000001").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, /http:\/\/dfile\.example\.org\/list_files\?api_key=test_key&show_catalogues=true&source_dir=PACKAGING:\d+/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&show_catalogues=true&source_dir=PACKAGING:").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})

      stub_request(:get, "http://dfile.example.org/list_files?api_key=test_key&show_catalogues=true&source_dir=PACKAGING:90000").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "http://dfile.example.org/move_to_trash?api_key=test_key&source_dir=PACKAGING:666").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})
    end
  end
end
