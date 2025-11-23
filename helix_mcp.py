from __future__ import annotations
import sys
import asyncio
import threading
import json
from fastmcp import FastMCP
from fastmcp.tools.tool import Tool
from helix.client import Client
from helix.types import GHELIX, RHELIX
from helix.embedding.embedder import Embedder
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any

# ======================
# Tool Configs
# ======================

class ToolConfig(BaseModel):
    """
    Enable/disable MCP tools. Defaults to enabled.
    """
    n_from_type: bool = Field(True, description="Enable n_from_type tool")
    e_from_type: bool = Field(True, description="Enable e_from_type tool")
    out_step: bool = Field(True, description="Enable out_step tool")
    out_e_step: bool = Field(True, description="Enable out_e_step tool")
    in_step: bool = Field(True, description="Enable in_step tool")
    in_e_step: bool = Field(True, description="Enable in_e_step tool")
    filter_items: bool = Field(True, description="Enable filter tool")
    search_vector: bool = Field(True, description="Enable search_v tool")
    search_vector_text: bool = Field(True, description="Enable search_v_text tool")
    search_keyword: bool = Field(True, description="Enable search_keyword tool")
    order_by: bool = Field(True, description="Enable order_by tool")
    group_by: bool = Field(True, description="Enable group_by tool")
    aggregate_by: bool = Field(True, description="Enable aggregate_by tool")


class MCPServer:
    """
    MCP server for HelixDB MCP endpoints. Specialized for graph traversal and search.

    Args:
        name (str): The name of the MCP server.
        client (Client): The Helix client.
        mcp_args (Optional[Dict[str, Any]]): Extra arguments to pass to the MCP server.
        verbose (bool): Whether to print verbose output.
        tool_config (ToolConfig): Enable/disable MCP tools.
        embedder (Optional[Embedder]): The embedder to use for vector search.

    Note:
        If embedder is not provided, search_vector tool will be disabled.
        If embedder is provided, search_vector_text tool will be disabled.
    """
    def __init__(
        self,
        name: str,
        client: Client,
        mcp_args: Optional[Dict[str, Any]] = {},
        verbose: bool=True,
        tool_config: ToolConfig = ToolConfig(),
        embedder: Optional[Embedder] = None,
        embedder_args: Optional[Dict[str, Any]] = {},
    ):
        self.mcp = FastMCP(name, **mcp_args)
        self.client = client
        self.verbose = verbose
        self.tool_config = tool_config
        self.embedder = embedder
        self.embedder_args = embedder_args
        if embedder is None:
            self.tool_config.search_vector = False
            self.tool_config.search_vector_text = True
        else:
            self.tool_config.search_vector = True
            self.tool_config.search_vector_text = False
        self._register_tools()

    def add_tool(self, tool: Tool):
        """
        Add a tool to the MCP server.

        Args:
            tool (Tool): The MCP tool to add.
        """
        self.mcp.add_tool(tool)

    def _register_tools(self) -> None:
        @self.mcp.tool()
        def init() -> str:
            """
            Initialize the MCP traversal connection

            Returns:
                str (The connection id)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP init", file=sys.stderr)
                result = self.client.query('mcp/init', {})[0]
                return "MCP init failed" if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP init failed: {e}")

        @self.mcp.tool(name="next")
        def next_item(connection_id: str) -> dict[str, Any]:
            """
            Get the next item in the traversal results

            Returns:
                Dict[str, Any] (The next item)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP next", file=sys.stderr)
                result = self.client.query('mcp/next', {'connection_id': connection_id})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP next failed: {e}")

        @self.mcp.tool()
        def collect(
            connection_id: str,
            range_start: int = 0,
            range_end: int = -1,
            drop: bool = True
        ) -> list[dict[str, Any]]:
            """
            Collect all items in the traversal results

            Args:
                connection_id: The connection id
                range_start: The start of the range (default: 0)
                range_end: The end of the range, -1 to get all items (default: -1)
                drop: Whether to reset the connection after collection (default: True)

            Returns:
                List[Dict[str, Any]] (List of collected items)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP collect", file=sys.stderr)
                payload = {'connection_id': connection_id}
                if range_start != 0 or range_end != -1:
                    payload['range'] = {'start': range_start, 'end': range_end}
                if not drop:
                    payload['drop'] = drop
                result = self.client.query('mcp/collect', payload)[0]
                if isinstance(result, dict):
                    result = [result]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP collect failed: {e}")

        @self.mcp.tool()
        def reset(connection_id: str) -> str:
            """
            Reset the MCP traversal connection

            Returns:
                str (The connection id)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP reset", file=sys.stderr)
                result = self.client.query('mcp/reset', {'connection_id': connection_id})[0]
                return "MCP reset failed" if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP reset failed: {e}")

        @self.mcp.tool()
        def schema_resource(connection_id: str) -> dict[str, Any]:
            """
            Get the schema for the given connection id

            Returns:
                {
                    "schema": {
                        "nodes": List[Dict[str, Any]],
                        "vectors": List[Dict[str, Any]],
                        "edges": List[Dict[str, Any]]
                    },
                    "queries": List[Dict[str, Any]]
                }
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP schema_resource", file=sys.stderr)
                result = self.client.query('mcp/schema_resource', {'connection_id': connection_id})[0]
                result = json.loads(result)
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP schema_resource failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.n_from_type)
        def n_from_type(connection_id: str, node_type: str) -> dict[str, Any]:
            """
            Retrieves all nodes of a given type

            Args:
                connection_id: The connection id
                node_type: The label/name of node to retrieve

            Returns:
                Dict[str, Any] (The first node of the given type)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP n_from_type", file=sys.stderr)
                result = self.client.query('mcp/n_from_type', {'connection_id': connection_id, 'data': {'node_type': node_type}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP n_from_type failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.e_from_type)
        def e_from_type(connection_id: str, edge_type: str) -> dict[str, Any]:
            """
            Retrieves all edges of a given type

            Args:
                connection_id: The connection id
                edge_type: The label/name of edge to retrieve

            Returns:
                Dict[str, Any] (The first edge of the given type)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP e_from_type", file=sys.stderr)
                result = self.client.query('mcp/e_from_type', {'connection_id': connection_id, 'data': {'edge_type': edge_type}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP e_from_type failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.out_step)
        def out_step(connection_id: str, edge_type: str, edge_label: str) -> dict[str, Any]:
            """
            Traverses out from current nodes or vectors in the traversal with the given edge label to nodes or vectors.
            Assumes that the current state of the traversal is a collection of nodes or vectors that is the source of the given edge label.

            Args:
                connection_id: The connection id
                edge_type: The target entity type. Use 'node' when traversing to nodes and 'vec' when traversing to vectors.
                edge_label: The label/name of edge to traverse out

            Returns:
                Dict[str, Any] (The first node of the traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP out_step", file=sys.stderr)
                result = self.client.query('mcp/out_step', {'connection_id': connection_id, 'data': {'edge_label': edge_label, 'edge_type': edge_type}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP out_step failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.out_e_step)
        def out_e_step(connection_id: str, edge_label: str) -> dict[str, Any]:
            """
            Traverses out from current nodes or vectors in the traversal to their edges with the given edge label.
            Assumes that the current state of the traversal is a collection of nodes or vectors that is the source of the given edge label.

            Args:
                connection_id: The connection id
                edge_label: The label/name of edge to traverse out

            Returns:
                Dict[str, Any] (The first edge of the traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP out_e_step", file=sys.stderr)
                result = self.client.query('mcp/out_e_step', {'connection_id': connection_id, 'data': {'edge_label': edge_label}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP out_e_step failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.in_step)
        def in_step(connection_id: str, edge_type: str, edge_label: str) -> dict[str, Any]:
            """
            Traverses in from current nodes or vectors in the traversal with the given edge label to nodes or vectors.
            Assumes that the current state of the traversal is a collection of nodes or vectors that is the target of the given edge label.

            Args:
                connection_id: The connection id
                edge_type: The target entity type. Use 'node' when traversing to nodes and 'vec' when traversing to vectors.
                edge_label: The label/name of edge to traverse into

            Returns:
                Dict[str, Any] (The first node of the traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP in_step", file=sys.stderr)
                result = self.client.query('mcp/in_step', {'connection_id': connection_id, 'data': {'edge_label': edge_label, 'edge_type': edge_type}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP in_step failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.in_e_step)
        def in_e_step(connection_id: str, edge_label: str) -> dict[str, Any]:
            """
            Traverses in from current nodes or vectors in the traversal to their edges with the given edge label.
            Assumes that the current state of the traversal is a collection of nodes or vectors that is the target of the given edge label.

            Args:
                connection_id: The connection id
                edge_label: The label/name of edge to traverse into

            Returns:
                Dict[str, Any] (The first edge of the traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP in_e_step", file=sys.stderr)
                result = self.client.query('mcp/in_e_step', {'connection_id': connection_id, 'data': {'edge_label': edge_label}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP in_e_step failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.filter_items)
        def filter_items(
            connection_id: str,
            properties: Optional[list[list[dict[str, Any]]]] = None,
            filter_traversals: Optional[list[dict[str, Any]]] = None
        ) -> dict[str, Any]:
            """
            Filters the current state of the traversal based on the given filter.

            Args:
                connection_id: The connection id
                properties: OR-of-ANDs filter for current traversal results.
                    The outer list represents an OR between property filters, meaning at least one of the inner lists must be true.
                    The inner list represents an AND group of property filters, meaning all filters in the inner list must be true.
                    Each filter dict should have: {"key": str, "operator": str, "value": Any}
                filter_traversals: Does traversals based on the tool to filter the current traversal results by future traversal results.
                    Uses AND logic, all traversal filters must be true.
                    Each traversal dict should have: {"tool_name": str, "args": dict}

            Returns:
                Dict[str, Any] (The first item of the traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP filter", file=sys.stderr)
                filters = {
                    "properties": properties or [],
                    "filter_traversals": filter_traversals or [],
                }
                payload = {'connection_id': connection_id, 'data': {'filter': filters}}
                result = self.client.query('mcp/filter_items', payload)[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP filter failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.search_vector)
        def search_vector(
            connection_id: str,
            query: str,
            k: int = 10,
            min_score: Optional[float] = None
        ) -> list[dict[str, Any]]:
            """
            Similarity searches the vectors in the traversal based on the given vector.
            Assumes that the current state of the traversal is a collection of vectors.

            Args:
                connection_id: The connection id
                query: The text query to search
                k: The number of results to return (default: 10)
                min_score: The minimum score to filter by, 0.0 to 1.0 (optional)

            Returns:
                List[Dict[str, Any]] (The first k vectors of the traversal result ordered by descending similarity)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP search_vector", file=sys.stderr)
                vector = self.embedder.embed(query, **self.embedder_args)
                result = self.client.query('mcp/search_vector', {'connection_id': connection_id, 'data': {'vector': vector, 'k': k, 'min_score': min_score}})[0]
                if isinstance(result, dict):
                    result = [result]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP search_vector failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.search_vector_text)
        def search_vector_text(connection_id: str, query: str, label: str) -> list[dict[str, Any]]:
            """
            Similarity searches the vectors in the traversal based on the given text query.

            Args:
                connection_id: The connection id
                query: The text query to search
                label: The label/name of the vector to search

            Returns:
                List[Dict[str, Any]] (The first 5 vectors of the traversal result ordered by descending similarity)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP search_vector_text", file=sys.stderr)
                result = self.client.query('mcp/search_vector_text', {'connection_id': connection_id, 'data': {'query': query, 'label': label}})[0]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP search_vector_text failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.search_keyword)
        def search_keyword(connection_id: str, query: str, label: str, limit: int = 10) -> list[dict[str, Any]]:
            """
            BM25 searches the nodes in the traversal based on the given keyword query and the node label.

            Args:
                connection_id: The connection id
                query: The text query to search
                label: The label/name of the node to search
                limit: The limit of results to return (default: 10)

            Returns:
                List[Dict[str, Any]] (The first k nodes of the traversal result ordered by descending similarity where k is the limit)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP search_keyword", file=sys.stderr)
                result = self.client.query('mcp/search_keyword', {'connection_id': connection_id, 'data': {'query': query, 'label': label, 'limit': limit}})[0]
                if isinstance(result, dict):
                    return [result]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP search_keyword failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.order_by)
        def order_by(connection_id: str, property: str, order: str = "asc") -> dict[str, Any]:
            """
            Orders the current traversal results by the given property in ascending or descending order.

            Args:
                connection_id: The connection id
                property: The property to order by
                order: The order to sort by: 'asc' or 'desc' (default: 'asc')

            Returns:
                Dict[str, Any] (The first item of the ordered traversal result)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP order_by", file=sys.stderr)
                result = self.client.query('mcp/order_by', {'connection_id': connection_id, 'data': {'properties': property, 'order': order}})[0]
                return {} if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP order_by failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.group_by)
        def group_by(connection_id: str, properties: list[str]) -> list[dict[str, Any]]:
            """
            Groups the current traversal results by the given properties. Returns a list of unique property combinations and their count.

            Args:
                connection_id: The connection id
                properties: The properties to group by

            Returns:
                List[Dict[str, Any]] (List of groups with unique property combinations and counts)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP group_by", file=sys.stderr)
                result = self.client.query('mcp/group_by', {'connection_id': connection_id, 'properties': properties})[0]
                if isinstance(result, dict):
                    return [result]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP group_by failed: {e}")

        @self.mcp.tool(enabled=self.tool_config.aggregate_by)
        def aggregate_by(connection_id: str, properties: list[str]) -> list[dict[str, Any]]:
            """
            Aggregates the current traversal results by the given properties. Returns a list of groups, each with a count and data as a list of items in that group.

            Args:
                connection_id: The connection id
                properties: The properties to aggregate by

            Returns:
                List[Dict[str, Any]] (List of aggregated groups with count and data)
            """
            try:
                if self.verbose: print(f"{GHELIX} MCP aggregate_by", file=sys.stderr)
                result = self.client.query('mcp/aggregate_by', {'connection_id': connection_id, 'properties': properties})[0]
                if isinstance(result, dict):
                    return [result]
                return [] if result is None else result
            except Exception as e:
                raise Exception(f"{RHELIX} MCP aggregate_by failed: {e}")

    def run(
        self,
        transport: str="streamable-http",
        host: str="127.0.0.1",
        port: int=8000,
        **run_args,
    ):
        """
        Run the MCP server.

        Args:
            transport (str, optional): The transport to use. Defaults to "streamable-http".
            host (str, optional): The host to use. Defaults to "127.0.0.1".
            port (int, optional): The port to use. Defaults to 8000.
            **run_args: Additional arguments to pass to the run method.
        """
        if transport == "stdio":
            self.mcp.run(transport="stdio")
        else:
            self.mcp.run(transport=transport, host=host, port=port, **run_args)

    async def run_async(
        self,
        transport: str="streamable-http",
        host: str="127.0.0.1",
        port: int=8000,
        **run_args,
    ):
        """
        Run the MCP server asynchronously.

        Args:
            transport (str, optional): The transport to use. Defaults to "streamable-http".
            host (str, optional): The host to use. Defaults to "127.0.0.1".
            port (int, optional): The port to use. Defaults to 8000.
            **run_args: Additional arguments to pass to the run method.
        """
        if transport == "stdio":
            await self.mcp.run_async(transport="stdio")
        else:
            await self.mcp.run_async(transport=transport, host=host, port=port, **run_args)

    def run_bg(
        self,
        transport: str="streamable-http",
        host: str="127.0.0.1",
        port: int=8000,
        **run_args,
    ) -> threading.Thread:
        """
        Start the MCP server in a non-blocking background thread.

        Returns:
            threading.Thread: The daemon thread running the server.
        """
        def _runner():
            if transport == "stdio":
                self.mcp.run(transport="stdio")
            asyncio.run(self.mcp.run_async(transport=transport, host=host, port=port, **run_args))

        t = threading.Thread(target=_runner, daemon=True)
        t.start()
        return t

