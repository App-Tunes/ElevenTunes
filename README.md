#  Eleven Tunes

Grand successor of Ten Tunes.

This media manager focuses on unifying representations of media into a simple, streamlined UI. Supports for more backends, read-only and write compatible, will be added over time.
 
 ## Setup
 
 * Place or symlink taglib to Frameworks/TagLib/taglib 
 * Place or symlink essentia to Frameworks/Essentia/essentia
 * Install essentia dependencies: brew install eigen ffmpeg libsamplerate libtag

 ## Backends
 
 * [✓] Audio Files (AVFoundation)
 * [✓] Spotify
 * [  ] Soundcloud
 * [  ] YouTube
 
 ## Architecture

The app is built on documents: Any number of libraries may be open at the same time. Many objects have limited remote connections to some backend, so content is requested on an on-demand basis (RequestMapper).

Many objects contain multiple layers of caches: Backend (source of truth), local cache, and database cache.

* **Branching**: Branching types are used to group the primary representation and some secondary representations. Secondary represenatations may be used to query additional content.
* **Playlist**: A playlist is an object that can refer to tracks and other playlists in meaningful ways. Perhaps counter to tradition, a playlist is not only a list of tracks by some user - it might be any meaningful track or playlist collection, including folders, artists, albums or users. 
* **Track**: Representation of some media. When played, it is asked to represent itself as an audio emitter.

### Player
Playing media files is offloaded into a hierarchy of responsibility. In order:

* **Player**: General user-directed media player. Keeps track of history and future, and preloads relevant items.
* **SinglePlayer**: A media-playing node capable of playing exactly one audio emitter at a time.
* **AudioEmitter**: Some sound-emitting node. This may not necessarily be local - but it is observable and controllable.
    * **AVFoundationAudioEmitter**: Classic local AudioEmitter, powered by AVFoundation.
    * **RemoteAudioEmitter**: Specialized AudioEmitter node that keeps a local cache for streamlined remote playback.

### Volatile Attributes

The main body of information propagation happens through VolatileAttributes. In this representation, a data object (e.g. Track, Playlist) may present any amount of data - as keyed by typed attribute keys. There are different layers using information in different formats - e.g. GUI, cache layer and backend interface (via requests). Each defines specific groups of data to be able to handle data properly - but since these groups are often unequal, in the interface each attribute must define its own load state. Handling these states gracefully is up to individual layers, although there are a bunch of logical utilities assisting in this.

* **RequestMapper**: Utility for remote representations to map attribute requests to asynchronous data streams.
* **TypedDict**: A dictionary accessible through typed properties.
* **KeyedDemand**: Keeps track of demand to inidivual attributes through auto-disposing demand objects. A view will maintain an active demand while shown, and if a cache is invalidated, information will auto-refresh through active demand.
