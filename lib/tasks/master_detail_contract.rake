namespace :wm do
  namespace :contracts do
    desc "master-detail 패턴 계약 테스트를 실행합니다."
    task master_detail: :environment do
      command = "ruby bin/rails test test/contracts/master_detail_pattern_contract_test.rb"
      success = system(command)

      if success
        puts "master-detail 계약 테스트가 통과했습니다."
      else
        abort "master-detail 계약 테스트가 실패했습니다."
      end
    end
  end
end
