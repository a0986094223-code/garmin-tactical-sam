using Toybox.Application as App;

class TacticalSAMApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }
    function getInitialView() {
        return [ new TacticalSAMView() ];
    }
}
