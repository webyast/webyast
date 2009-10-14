require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
class RegistrationTest < ActiveSupport::TestCase

  CONTEXT = { 'yastcall'     => [ 'i', 1 ],
              'norefresh'    => [ 'i', 1 ],
              'restoreRepos' => [ 'i', 1 ],
              'forcereg'     => [ 'i', 0 ],
              'nohwdata'     => [ 'i', 1 ],
              'nooptional'   => [ 'i', 1 ],
              'debugMode'    => [ 'i', 2 ],
              'logfile'      => [ 's', '/root/.suse_register.log' ] }
 
  ARGUMENTS = {}

  RESPONSE = { 'status'=>'finished',
        'exitcode'=>0,
        'guid'=>1234,
        'missingarguments'=>[{'name'=>'missingkey', 'type'=>'string'}],
        'changedrepos'=>[{'name'=>'repoName', 
                          'alias'=>'myRepoName', 
                          'urls'=>['http://some.host/repo/xy'],
                          'priority'=>80,
                          'autorefresh'=>true,
                          'enabled'=>true,
                          'status'=>'added'}],
        'changedservices'=>[{'name'=>'some-serv1',
                             'url'=>'http://some.host/services/serv1',
                             'status'=>'added'}]
      }

  def setup    
    YastService.stubs(:Call).with("YSR::statelessregister", { 'ctx' => CONTEXT, 'arguments' => ARGUMENTS }).returns(RESPONSE)
  end

  def test_getter
#    registration = Registration.find
#    assert_equal("compare_value", registration.<member>) FIXME when values available
  end

  def test_setter
#    registration = Registration.find
    #changing values --> FIXME
#    registration.save
  end

  def test_setter
#    registration = Registration.new
    #changing values --> FIXME
#    registration.register
  end

  def test_xml
#    registration = Registration.find
#    response = Hash.from_xml(registration.to_xml)
#    assert_equal("foo", response["bar"])  FIXME when data is available
  end

  def test_json
#    registration = Registration.find
#    assert_not_nil(registration.to_json)
  end

end
