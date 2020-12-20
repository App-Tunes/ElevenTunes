#  Eleven Tunes

Grand successor of Ten Tunes.
This media manager focuses on unifying representations of media into a simple, streamlined UI. Supports for more backends, read-only and write compatible, will be added over time.
 
 ## Architecture

The app is built on documents: Any number of libraries may be open at the same time. 

**Track**: Representation of a media file. It consists of a cached frontend (queriable real-time), and a connection to some backend (source of truth). When played, it is asked to represent itself as an audio emitter.

**Playlist**: Representation of a collection. It consists of a cached frontend (queriable real-time), and a connection to some backend (source of truth). It contains items (tracks), and children (playlists). In the navigator, playlists marked as directories can be expanded to reveal its children.

### Player
Playing media files is offloaded into a hierarchy of responsibility. In order:

* **Player**: General user-directed media player. Keeps track of history and future, and preloads relevant items.
* **SinglePlayer**: A media-playing node capable of playing exactly one audio emitter at a time.
* **AudioEmitter**: Some sound-emitting node. This may not necessarily be local - but it is observable and controllable.
* **AVFoundationAudioEmitter**: Classic local AudioEmitter, powered by AVFoundation.
* **RemoteAudioEmitter**: Specialized AudioEmitter node that keeps a local cache for streamlined remote playback.
