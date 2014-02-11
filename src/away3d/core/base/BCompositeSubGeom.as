package away3d.core.base {

	import flash.display3D.IndexBuffer3D;
	import flash.utils.Endian;
	import flash.utils.ByteArray;
	import away3d.bounds.BoundingBox;
	import flash.utils.Dictionary;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.VertexBuffer3D;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeSubGeom
	 */
	public class BCompositeSubGeom extends BinarySubGeometry {
		
		// static buffer for index buff upload
		private static const BUFF : ByteArray = new ByteArray();
		
		private var _source : BCompositeSubGeomSource;
		private var _groups : Vector.<uint>;

		public function BCompositeSubGeom(source : BCompositeSubGeomSource ) {
			_source = source;
			autoDeriveVertexNormals = 
			autoDeriveVertexTangents = false;
			super();
		}
		
		
		override public function contributeBounds(bb : BoundingBox) : void {
			_source.contributeBounds(bb);
		}
		
		
		override public function dispose() : void {
			_source = null;
			_groups = null;
			super.dispose();
		}

		public function getGroups() : Vector.<uint> {
			return _groups;
		}

		public function hasGroup( id : uint ) : Boolean {
			for (var i : int = 0; i < _groups.length; i++) 
				if( _groups[i] == id ) return true;
			return false;
		}

		public function hasGroups( eg : Vector.<uint> ) : Boolean {
			var subhas : Boolean;
			var id : uint;
			for (var j : int = 0; j < eg.length; j++) {
				subhas = false;
				id = eg[j];
				for (var i : int = 0; i < _groups.length; i++) {
					if( _groups[i] == id ) {
						subhas = true;
						break;
					}
				}
				if( ! subhas ) return false;
			}
			return true;
		}


		public function removeGroups( remove : Vector.<uint> ) : void {
			for (var i : int = _groups.length-1; i > -1; i--) {
				if( remove.indexOf( _groups[i] ) > -1 ) _groups.splice(i, 1);
			}
			setGroups( _groups );
		}
		
		
		public function addGroups(add : Vector.<uint>) : void {
			for (var i : int = 0; i < add.length; i++) {
				if( _groups.indexOf( add[i] ) == -1 ) _groups.push( add[i] );
			}
			setGroups( _groups );
		}


		public function setGroups(groups : Vector.<uint> = null, invert : Boolean = false) : void {
			
			var groupsIds : Vector.<uint> = _source.groupsIds;
			var sg : Dictionary = _source.groups;
			
			if( groups == null ) 
				groups = _source.groupsIds;
				
			var i : int;
			var head : IndicesRange;
			
			if( invert ) {
				var ng : Vector.<uint> = new Vector.<uint>();
				for ( i = 0; i < groupsIds.length; i++) {
					if( groups.indexOf( groupsIds[i] ) == -1 ) 
						ng.push( groupsIds[i] );
				}
				groups = ng;
			} 
			
			var numIndices : int = 0;
			_groups = new Vector.<uint>( groups.length );
			for ( i = 0; i < groups.length; i++) {
				head = sg[ groups[i] ];
				if( head == null )
					throw new Error( "away3d.core.base.BCompositeSubGeom - setGroups : no group #"+groups[i] );
				numIndices += head.numIndices;
				_groups[i] = groups[i];
			}
			
			
//			trace( "away3d.core.base.BCompositeSubGeom - setGroups -- gl", _groups.length );
//			trace( "away3d.core.base.BCompositeSubGeom - setGroups -- il", indices.length );
			
			setNumIndices( numIndices );
		}

		override protected function _uploadIndex(indexBuffer : IndexBuffer3D) : void {
			var bytes : ByteArray = _source.gindexData;
			var sg : Dictionary = _source.groups;
			var head : IndicesRange;
			var ioff : int = 0;
			
			BUFF.position = 0;
			
			for ( var i : int = 0; i < _groups.length; i++) {
				head = sg[ _groups[i] ];
				
				BUFF.writeBytes(bytes, head.bytesOffset, head.numIndices*2 );
				// multiple upload is unstable in ios
//				indexBuffer.uploadFromByteArray(buff, head.bytesOffset, ioff, head.numIndices);
				
				ioff += head.numIndices;
			}
			indexBuffer.uploadFromByteArray(BUFF,0, 0, ioff);
			
		}
		
		private function setNumIndices( numIndices : int = 0 ) : void
		{
			_numIndices = numIndices;

			var numTriangles : int = (_numIndices/3);
			if (_numTriangles != numTriangles)
				disposeIndexBuffers(_indexBuffer);
			_numTriangles = numTriangles;
			invalidateBuffers(_indexBufferContext);
			_faceNormalsDirty = true;

			if (_autoDeriveVertexNormals) _vertexNormalsDirty = true;
			if (_autoDeriveVertexTangents) _vertexTangentsDirty = true;
		}
		
		override public function get numVertices() : uint
		{
			return _source.numVertices;
		}

		
		override public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexBuffer(stage3DProxy);
		}

		override public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getUVBuffer(stage3DProxy);
		}
		
		override public function getSecondaryUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getSecondaryUVBuffer(stage3DProxy);
		}
		
		override public function getVertexNormalBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexNormalBuffer(stage3DProxy);
		}

		override public function getVertexTangentBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexTangentBuffer(stage3DProxy);
		}
		
		
		override public function get vertexData() : ByteArray
		{
			return _source.vertexData;
		}

	}
}
