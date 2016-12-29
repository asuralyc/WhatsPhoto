
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.define("incrementUseCount", function(request, response) {
  Parse.Cloud.useMasterKey();

  var Quote = Parse.Object.extend("Quote");
  var quote = new Quote();

  quote.id = request.params.quoteId;
  var increment = request.params.increment;

  quote.increment("useCount", increment);
  quote.save(null, {
      success: function(quote) {
        response.success(true);
      },
      error: function(quote, error) {
        response.error("Could not increment use count of Quote.");
      }
  });
});

Parse.Cloud.define("incrementReportCount", function(request, response) {
  Parse.Cloud.useMasterKey();

  var Quote = Parse.Object.extend("Quote");
  var quote = new Quote();

  quote.id = request.params.quoteId;
  var increment = request.params.increment;

  quote.increment("reportCount", increment);
  quote.save(null, {
      success: function(quote) {
        response.success(true);
      },
      error: function(quote, error) {
        response.error("Could not increment report count of Quote.");
      }
  });
});

Parse.Cloud.define("markQuoteAsHidden", function(request, response) {
  Parse.Cloud.useMasterKey();

  var Quote = Parse.Object.extend("Quote");
  var quote = new Quote();

  quote.id = request.params.quoteId;
  quote.increment("reportCount", 1);
  quote.set("visibleType", 1);
  quote.save(null, {
      success: function(quote) {
        response.success(true);
      },
      error: function(quote, error) {
        response.error("Could not mark Quote as hidden.");
      }
  });
});