module Requests
  module StubRequests
    def global_stubs
      stub_request(:get, /http:\/\/localhost:3001\/download_file\?source_file=PACKAGING:\/.+\/pdf\/.+\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, /http:\/\/localhost:3001\/download_file.json\?source_file=STORE:\/.+\/pdf\/.+\.pdf/).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "http://localhost:3001/download_file?source_file=PACKAGING://pdf/.pdf").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 404, :body => "", :headers => {})
    end
  end
end