# AmqpHelper

This is just an attempt to standardize and make more reusable some
of the AMQP code that I use in various pieces of the Medusa project,
e.g. in the collection registry and amazon backup.  

As such it may make certain assumptions that are true for these 
projects but not more generally, e.g. that it is running in the 
presence of Rails. These may or may not be removed at some point.
Also our usage is relatively simple and this is geared toward that
viewpoint.

We do hope to make this work with both MRI and JRuby though, as
we have code that runs under each. For starters it will be just MRI
though; code for JRuby will be added if and when needed. 

# Usage

Add the gem to your Gemfile:

```ruby
gem "amqp_helper", git: "https://github.com/medusa-project/amqp_helper.git"
```

Add an  `amqp.yml` file to the `config` directory of your Rails project. The
file should look something like this:

```yaml
default: &default
  ssl:                  false
  verify:               verify_none
  verify_peer:          false
  fail_if_no_peer_cert: false
  heartbeat:            10

development:
  <<:        *default
  ssl:      false
  host:     # fill me in
  user:     # fill me in
  password: # fill me in

test:
  <<:        *default
  host:     # fill me in
  user:     # fill me in
  password: # fill me in

production:
  <<:        *default
  ssl:      true
  host:     # fill me in
  user:     # fill me in
  password: # fill me in
  vhost:    medusa
  verify:   false
```

Add an initializer to the `config/initializers` directory of your Rails project
containing something like the following:

```ruby
settings_path     = File.join(Rails.root, 'config', 'amqp.yml')
settings          = YAML.load(ERB.new(File.read(settings_path)).result, aliases: true)[Rails.env]
settings[:logger] = Rails.logger

AmqpHelper::Connector.new(:ideals, settings)
```
