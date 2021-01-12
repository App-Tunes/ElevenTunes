#  Eleven Tunes

Grand successor of Ten Tunes.
This media manager focuses on unifying representations of media into a simple, streamlined UI. Supports for more backends, read-only and write compatible, will be added over time.
 
 ## Architecture

The app is built on documents: Any number of libraries may be open at the same time. Many objects have limited remote connections to some backend, so much of the content is requested on an on-demand basis (CurrentValueSubjectPublishingDemand + FeatureSet) with the Combine API. Be wary that due to limited backends, any operation may be rejected. Usually, objects offer two functions for any operation - querying general support for it, and then a deferred operation without return value actually attempting to execute it.

### Playlist

A playlist is an object that can refer to tracks and other playlists in meaningful ways. Perhaps contrary to tradition, a playlist is not only a list of tracks by some user - it might be any meaningful track or playlist collection, including folders, artists, albums or users. 

**DBPlaylist**: Any playlist might be cached by a database representation. Only those that are can be searched or filtered on the fly (indexing a playlist will also add children and tracks to the database). A DB playlist does not necessitate a backend. It might be specifically detached by the user. A backend *can* support any number of interactive operations, but most don't: A spotify playlist will (probably) never accept a soundcloud link as a track. A DB playlist detached from any backend however can. 

### Track

Representation of a media file. It consists of a cached frontend (queriable real-time), and a connection to some backend (source of truth). When played, it is asked to represent itself as an audio emitter.

**DBTrack**: Any track might be cached by a database representation. Only those that are are searchable or filterable on the fly. A backend can be exchanged - consider a user purchasing a track he previously kept a spotify link to. It is likely that he wants to exchange the backend for the file representation. In the future, secondary backends enabling syncable states (e.g. back to spotify, even with a physical file track) might be added.

### Player
Playing media files is offloaded into a hierarchy of responsibility. In order:

* **Player**: General user-directed media player. Keeps track of history and future, and preloads relevant items.
* **SinglePlayer**: A media-playing node capable of playing exactly one audio emitter at a time.
* **AudioEmitter**: Some sound-emitting node. This may not necessarily be local - but it is observable and controllable.
* **AVFoundationAudioEmitter**: Classic local AudioEmitter, powered by AVFoundation.
* **RemoteAudioEmitter**: Specialized AudioEmitter node that keeps a local cache for streamlined remote playback.

### VolatileAttributes

The main body of information propagation happens through VolatileAttributes. In this representation, any data object (e.g. Track, Playlist) may present any amount of data - as keyed by typed attribute keys. There are different layers using information in different formats - e.g. GUI, cache layer and backend interface (via requests). Each defines specific groups of data to be able to handle data properly - but since these groups are often unequal, in the interface each attribute must define its own load state. Handling these states gracefully is up to individual layers, although there are a bunch of logical utilities assisting in this.

* **SetRelation**: Relationship between two sets. Often used to map e.g. requests to attributes.
* **TypedDict**: A dictionary accessible through typed properties.
* **KeyedDemand**: Keeps track of demand to inidivual attributes through auto-disposing demand objects. A view will maintain an active demand while shown, and if a cache is invalidated, information will auto-refresh through active demand.
* **RequestMapper**: Implementation for mapping attribute demand to requests fetching remote properties. 
