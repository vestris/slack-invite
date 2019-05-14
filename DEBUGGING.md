## Debugging

### Locally

You can debug your instance of slack-invite with a built-in `script/console`.

### Silence Mongoid Logger

If Mongoid logging is annoying you.

```ruby
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO
```
