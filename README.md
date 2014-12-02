# Lanes

This helpful little command line tool helps manage "lanes" of servers on AWS.

TODO: Describe lanes philosophy


## Installation & Usage

1. Create some default profiles (TODO: have the app generate this itself)
```
mkdir ~/.lanes
echo 'profile: myapp' >> ~/.lanes/lanes.yml
cat <<EOF >> ~/.lanes/myapp.yml
aws_access_key_id: [AWS_ACCESS_KEY_HERE
aws_secret_access_key: [AWS_SECRET_KEY_HERE]
ssh:
   mods:
      dev:
         identity: ~/.ssh/myapp-dev.pem
         tunnel: 7979:localhost:5432
EOF
```
2. Install the gem: `gem install awslanes`
3. Run it and toy around: `lanes`


## Contributing

1. Fork it ( https://github.com/lemniscate/aws-lanes/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
